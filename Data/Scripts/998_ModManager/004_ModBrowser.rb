#==============================================================================
# Mod Manager — Mod Browser
#
# Fetches mod catalog from GitHub (KIF-Mods/mods repo), lets users browse
# and install/update mods. Uses public GitHub API + raw.githubusercontent.com.
#==============================================================================

module ModManager
  #============================================================================
  # Debug logger — writes to modmanager_debug.txt in game root
  #============================================================================
  def self.debug_log(msg)
    File.open("modmanager_debug.txt", "a") do |f|
      f.puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}"
    end
  rescue
  end

  #============================================================================
  # GitHub API helpers
  #============================================================================
  module GitHub
    REPO_OWNER = "KIF-Mods"
    REPO_NAME  = "mods"
    REPO_API   = "https://api.github.com/repos/#{REPO_OWNER}/#{REPO_NAME}/contents/"
    RAW_BASE   = "https://raw.githubusercontent.com/#{REPO_OWNER}/#{REPO_NAME}/main/"

    # KIF Multiplayer official repo
    # NOTE: updates/<ver>/v<ver>.7z is tracked by Git LFS, so raw.githubusercontent.com
    # returns the 134-byte pointer instead of the real archive. Use GitHub's LFS-aware
    # media endpoint instead — it resolves LFS objects to the actual file content.
    # (The old releases/latest/download/ path 404s whenever the Release page isn't
    # manually synced to the repo's latest version.)
    MP_REPO_OWNER = "sKarreku"
    MP_REPO_NAME  = "KIF-Multiplayer"
    MP_RAW_BASE   = "https://raw.githubusercontent.com/#{MP_REPO_OWNER}/#{MP_REPO_NAME}/main/"
    MP_LFS_BASE   = "https://media.githubusercontent.com/media/#{MP_REPO_OWNER}/#{MP_REPO_NAME}/main/updates/"

    @@cache_mod_list = nil
    @@cache_mod_json = {}
    @@cache_time = 0
    @@just_installed = {}  # persists across Scene_Browser instances until restart
    CACHE_TTL = 120  # seconds

    def self.clear_cache
      @@cache_mod_list = nil
      @@cache_mod_json.clear
      @@cache_time = 0
    end

    def self.just_installed
      @@just_installed
    end

    def self.mark_installed(folder)
      @@just_installed[folder] = true
    end

    # Access cached data for use by other scenes (e.g. Modder Tools)
    def self.cached_mod_list
      @@cache_mod_list
    end

    def self.cached_mod_json
      @@cache_mod_json
    end

    # ── KIF Multiplayer helpers ──────────────────────────────────────────

    @@mp_remote_version = nil
    @@mp_checked = false

    def self.fetch_mp_remote_version
      return @@mp_remote_version if @@mp_checked
      begin
        raw = pbDownloadToString("#{MP_RAW_BASE}version.txt")
        if raw && !raw.empty? && raw.strip.match?(/^\d+\.\d+/)
          @@mp_remote_version = raw.strip
        end
      rescue => e
        echoln("[ModBrowser] MP version check error: #{e.message}")
      end
      @@mp_checked = true
      @@mp_remote_version
    end

    def self.mp_local_version
      if defined?(MultiplayerVersion::CURRENT_VERSION)
        return MultiplayerVersion::CURRENT_VERSION
      end
      nil
    end

    def self.mp_archive_url(version)
      "#{MP_LFS_BASE}#{version}/v#{version}.7z"
    end

    def self.mp_installed?
      # Multiplayer is installed if 659_Multiplayer folder exists
      File.directory?("Data/Scripts/659_Multiplayer")
    end

    # ── Aleks Full Implementation (NPT) helpers ─────────────────────────
    # Hosted on GitHub Releases: sKarreku/Aleks-Full-Implementation
    AFI_REPO = "sKarreku/Aleks-Full-Implementation"
    AFI_API  = "https://api.github.com/repos/#{AFI_REPO}/releases/latest"

    @@afi_manifest = nil
    @@afi_manifest_checked = false

    def self.npt_installed?
      File.directory?("Data/Scripts/990_NPT")
    end

    def self.npt_local_version
      if defined?(NPTVersion::CURRENT_VERSION)
        return NPTVersion::CURRENT_VERSION
      end
      nil
    end

    # Fetch the latest release metadata from GitHub API and build a manifest-like hash.
    # Avoids downloading the manifest.json release asset (redirect not supported).
    # All needed info (version, sizes, filenames) is in the API response itself.
    def self.fetch_afi_manifest
      return @@afi_manifest if @@afi_manifest_checked
      begin
        raw = pbDownloadToString(AFI_API)
        return nil unless raw && !raw.empty?
        release = ModManager::JSON.parse(raw)
        return nil unless release && release["assets"]

        assets = release["assets"]

        # Code archive
        code_asset = assets.find { |a| a["name"] =~ /code\.7z$/i }
        code_size  = code_asset ? code_asset["size"].to_i : nil
        code_file  = code_asset ? code_asset["name"] : nil

        # Version: from code filename "v4.1.0_code.7z" -> "4.1.0", fallback to tag
        version = code_file&.match(/^v([\d.]+)_code/i)&.captures&.first
        version ||= (release["tag_name"] || "").sub(/^v/, "")

        # Asset parts
        part_assets = assets.select { |a| a["name"] =~ /assets\.7z\.\d+$/i }.sort_by { |a| a["name"] }
        total_asset_size = part_assets.sum { |a| a["size"].to_i }
        asset_files = part_assets.map { |a| a["name"] }

        @@afi_manifest = {
          "version"    => version,
          "code"       => { "file" => code_file, "size" => code_size },
          "assets"     => {
            "parts"      => part_assets.length,
            "files"      => asset_files,
            "total_size" => total_asset_size
          }
        }
        @@afi_manifest_checked = true
        @@afi_manifest
      rescue => e
        echoln("[ModManager] AFI manifest fetch error: #{e.message}")
        nil
      end
    end

    def self.npt_remote_version
      manifest = fetch_afi_manifest
      manifest ? manifest["version"] : nil
    end

    # Size info for display
    def self.npt_code_size
      manifest = fetch_afi_manifest
      return nil unless manifest && manifest["code"]
      manifest["code"]["size"]
    end

    def self.npt_assets_size
      manifest = fetch_afi_manifest
      return nil unless manifest && manifest["assets"]
      manifest["assets"]["total_size"]
    end

    def self.npt_assets_parts
      manifest = fetch_afi_manifest
      return 0 unless manifest && manifest["assets"]
      manifest["assets"]["parts"] || 0
    end

    # Returns array of folder names (mod IDs) or nil on error
    # Tries two methods:
    #   1. Raw GitHub index file (mods_index.json) — fast, no API limits
    #   2. GitHub API contents listing — fallback
    def self.fetch_mod_list
      now = Time.now.to_i
      if @@cache_mod_list && (now - @@cache_time) < CACHE_TTL
        return @@cache_mod_list
      end

      folders = nil
      debug_log = []

      # GitHub API contents listing
      begin
        url = REPO_API
        debug_log << "Fetching: #{url}"
        raw = pbDownloadToString(url)
        debug_log << "Response length: #{raw.to_s.bytesize}"
        debug_log << "Response encoding: #{raw.to_s.encoding rescue 'unknown'}"
        debug_log << "Response preview: #{raw.to_s[0..300]}"
        if raw && raw.is_a?(String) && !raw.empty?
          # Normalize encoding: HTTPLite may return ASCII-8BIT (binary) strings.
          # ModManager::JSON.read_string builds out='' (UTF-8) and does out<<ch which raises
          # Encoding::CompatibilityError if ch is ASCII-8BIT with high bytes.
          raw_utf8 = raw.dup
          begin
            raw_utf8.force_encoding('UTF-8')
            unless raw_utf8.valid_encoding?
              raw_utf8 = raw.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?')
            end
          rescue => enc_err
            debug_log << "Encoding normalize error: #{enc_err.message}"
            raw_utf8 = raw
          end
          # Strip BOM if present
          raw_utf8 = raw_utf8.sub(/\A\xEF\xBB\xBF/, '').strip
          debug_log << "Normalized preview: #{raw_utf8[0..100]}"
          begin
            parsed = ModManager::JSON.parse(raw_utf8)
            debug_log << "Parsed type: #{parsed.class}"
          rescue => parse_err
            debug_log << "Parse EXCEPTION: #{parse_err.class}: #{parse_err.message}"
            debug_log << "  at: #{parse_err.backtrace.first(2).join(' | ') rescue '?'}"
            parsed = nil
          end
          if parsed.is_a?(Array)
            folders = []
            parsed.each do |entry|
              next unless entry.is_a?(Hash)
              next unless entry["type"] == "dir"
              name = entry["name"].to_s
              next if name.empty? || name.start_with?(".")
              next if name == "modpacks"
              folders << name
            end
            debug_log << "Found #{folders.length} mod folder(s): #{folders.inspect}"
          else
            debug_log << "Unexpected parsed type, not Array"
          end
        else
          debug_log << "Empty or non-string response"
        end
      rescue => e
        debug_log << "API error: #{e.class}: #{e.message}"
        debug_log << "  at: #{e.backtrace.first(2).join(' | ') rescue '?'}"
      end

      # Write debug log to file
      begin
        File.open("mod_browser_debug.txt", "w") { |f| f.puts debug_log.join("\n") }
      rescue; end

      if folders && !folders.empty?
        @@cache_mod_list = folders
        @@cache_time = now
      end

      folders
    end

    # Returns parsed mod.json hash for a remote mod, or nil
    def self.fetch_mod_json(folder)
      return @@cache_mod_json[folder] if @@cache_mod_json[folder]

      begin
        url = "#{RAW_BASE}#{folder}/mod.json"
        raw = pbDownloadToString(url)
        return nil unless raw && !raw.empty?

        raw_utf8 = raw.dup
        begin
          raw_utf8.force_encoding('UTF-8')
          raw_utf8 = raw.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '?') unless raw_utf8.valid_encoding?
        rescue; raw_utf8 = raw; end
        raw_utf8 = raw_utf8.sub(/\A\xEF\xBB\xBF/, '').strip

        parsed = ModManager::JSON.parse(raw_utf8)
        return nil unless parsed.is_a?(Hash) && parsed["id"]

        @@cache_mod_json[folder] = parsed
        parsed
      rescue => e
        echoln("[ModBrowser] Error fetching mod.json for #{folder}: #{e.message}")
        nil
      end
    end

    # Download a mod's files into Mods/<folder>/
    # Recursively handles subdirectories (Graphics/, Audio/, etc.)
    def self.download_mod(folder)
      begin
        target_dir = File.join(ModManager::MOD_DIR, folder)
        Dir.mkdir(target_dir) unless File.directory?(target_dir)
        downloaded = _download_dir(folder, target_dir)
        echoln("[ModBrowser] Downloaded #{downloaded} file(s) for #{folder}")
        # Install assets (Graphics/, Audio/, etc.) to game root
        ModManager.install_assets(folder)
        downloaded > 0
      rescue => e
        echoln("[ModBrowser] Error downloading mod #{folder}: #{e.message}")
        false
      end
    end

    # Recursively download all files from a GitHub directory
    def self._download_dir(repo_path, local_dir)
      url = "#{REPO_API}#{repo_path}"
      raw = pbDownloadToString(url)
      return 0 unless raw && !raw.empty?

      entries = ModManager::JSON.parse(raw)
      return 0 unless entries.is_a?(Array)

      downloaded = 0
      entries.each do |entry|
        next unless entry.is_a?(Hash)
        name = entry["name"].to_s
        next if name.empty?

        if entry["type"] == "file"
          file_url = "#{RAW_BASE}#{repo_path}/#{name}"
          target_path = File.join(local_dir, name)
          begin
            pbDownloadToFile(file_url, target_path)
            downloaded += 1
          rescue => e
            echoln("[ModBrowser] Failed to download #{name}: #{e.message}")
          end
        elsif entry["type"] == "dir"
          sub_dir = File.join(local_dir, name)
          Dir.mkdir(sub_dir) unless File.directory?(sub_dir)
          downloaded += _download_dir("#{repo_path}/#{name}", sub_dir)
        end
      end
      downloaded
    end

    # Check if a remote mod has a newer version than installed
    def self.has_update?(mod_id, remote_json)
      local = ModManager.get_mod(mod_id)
      return false unless local && remote_json
      ModManager.compare_versions(remote_json["version"].to_s, local.version) > 0
    end

    # Download a directory with a per-file progress callback
    # Callback receives: callback.call(filename, files_so_far)
    def self.download_dir_with_progress(repo_path, local_dir, &callback)
      _download_dir_cb(repo_path, local_dir, [0], &callback)
    end

    def self._download_dir_cb(repo_path, local_dir, counter, &callback)
      url = "#{REPO_API}#{repo_path}"
      raw = pbDownloadToString(url)
      return 0 unless raw && !raw.empty?

      entries = ModManager::JSON.parse(raw)
      return 0 unless entries.is_a?(Array)

      downloaded = 0
      entries.each do |entry|
        next unless entry.is_a?(Hash)
        name = entry["name"].to_s
        next if name.empty?

        if entry["type"] == "file"
          file_url = "#{RAW_BASE}#{repo_path}/#{name}"
          target_path = File.join(local_dir, name)
          begin
            pbDownloadToFile(file_url, target_path)
            downloaded += 1
            counter[0] += 1
            callback.call(name, counter[0]) if callback
          rescue => e
            echoln("[ModBrowser] Failed to download #{name}: #{e.message}")
          end
        elsif entry["type"] == "dir"
          sub_dir = File.join(local_dir, name)
          Dir.mkdir(sub_dir) unless File.directory?(sub_dir)
          downloaded += _download_dir_cb("#{repo_path}/#{name}", sub_dir, counter, &callback)
        end
      end
      downloaded
    end

    # Count files in a GitHub directory (for progress bar total)
    def self.count_remote_files(repo_path)
      url = "#{REPO_API}#{repo_path}"
      raw = pbDownloadToString(url)
      return 0 unless raw && !raw.empty?

      entries = ModManager::JSON.parse(raw)
      return 0 unless entries.is_a?(Array)

      count = 0
      entries.each do |entry|
        next unless entry.is_a?(Hash)
        if entry["type"] == "file"
          count += 1
        elsif entry["type"] == "dir"
          count += count_remote_files("#{repo_path}/#{entry["name"]}")
        end
      end
      count
    end

    # ── Mod Manager self-update helpers ──────────────────────────────────
    # MM is distributed as a single .rar from its own canonical repo
    # (KIF-Mods/mod-manager) — completely independent from the Multiplayer
    # update flow. The rar is small (<1 MB) so it's not LFS-tracked; raw
    # URLs work fine.

    @@mm_remote_version = nil
    @@mm_checked = false

    MM_REPO_OWNER = "KIF-Mods"
    MM_REPO_NAME  = "mod-manager"
    MM_REPO_RAW   = "https://raw.githubusercontent.com/#{MM_REPO_OWNER}/#{MM_REPO_NAME}/main/"
    # raw.githubusercontent.com caches aggressively (~5 min) and ignores
    # Pragma: no-cache + query strings. Hit the contents API instead — it
    # always returns fresh JSON with base64-encoded content.
    MM_VERSION_URL = "https://api.github.com/repos/#{MM_REPO_OWNER}/#{MM_REPO_NAME}/contents/version.txt"
    MM_ARCHIVE_URL = "#{MM_REPO_RAW}KIF-ModManager.7z"

    def self.fetch_mm_remote_version
      return @@mm_remote_version if @@mm_checked
      begin
        raw = pbDownloadToString(MM_VERSION_URL)
        if raw && !raw.empty?
          parsed = nil
          # API JSON response — base64 content field
          if raw.include?('"content"')
            m = raw.match(/"content"\s*:\s*"([^"]+)"/)
            if m
              decoded = m[1].gsub('\\n', '').unpack("m")[0].to_s.strip
              parsed = decoded if decoded.match?(/^\d+\.\d+/)
            end
          # Fallback: plain text response
          elsif raw.strip.match?(/^\d+\.\d+/)
            parsed = raw.strip
          end
          @@mm_remote_version = parsed if parsed
        end
      rescue => e
        echoln("[ModManager] MM version check error: #{e.message}")
      end
      @@mm_checked = true
      @@mm_remote_version
    end

    def self.mm_local_version
      defined?(ModManagerVersion::CURRENT_VERSION) ? ModManagerVersion::CURRENT_VERSION : nil
    end

    def self.mm_update_available?
      remote = fetch_mm_remote_version
      local = mm_local_version
      return false unless remote && local
      ModManager.compare_versions(remote, local) > 0
    end

    def self.reset_mm_check
      @@mm_checked = false
      @@mm_remote_version = nil
    end

    # ── Modpack helpers ──────────────────────────────────────────────────

    @@cache_modpack_list = nil
    @@cache_modpack_json = {}
    @@cache_modpack_time = 0

    def self.fetch_modpack_list
      now = Time.now.to_i
      if @@cache_modpack_list && (now - @@cache_modpack_time) < CACHE_TTL
        return @@cache_modpack_list
      end

      folders = nil
      begin
        url = "#{REPO_API}modpacks"
        raw = pbDownloadToString(url)
        if raw && raw.is_a?(String) && !raw.empty?
          parsed = ModManager::JSON.parse(raw) rescue nil
          if parsed.is_a?(Array)
            folders = []
            parsed.each do |entry|
              next unless entry.is_a?(Hash)
              next unless entry["type"] == "dir"
              name = entry["name"].to_s
              next if name.empty? || name.start_with?(".")
              folders << name
            end
          elsif parsed.is_a?(Hash) && parsed["type"] == "dir"
            folders = [parsed["name"].to_s]
          end
        end
      rescue => e
        echoln("[ModBrowser] Modpack list error: #{e.message}")
      end

      if folders && !folders.empty?
        @@cache_modpack_list = folders
        @@cache_modpack_time = now
      end

      folders
    end

    def self.fetch_modpack_json(folder)
      return @@cache_modpack_json[folder] if @@cache_modpack_json[folder]
      begin
        url = "#{RAW_BASE}modpacks/#{folder}/modpack.json"
        raw = pbDownloadToString(url)
        return nil unless raw && !raw.empty?
        parsed = ModManager::JSON.parse(raw)
        return nil unless parsed.is_a?(Hash)
        @@cache_modpack_json[folder] = parsed
        parsed
      rescue => e
        echoln("[ModBrowser] Error fetching modpack.json for #{folder}: #{e.message}")
        nil
      end
    end

    def self.cached_modpack_json
      @@cache_modpack_json
    end
  end

  #============================================================================
  # Progress Overlay — full-screen modal for batch downloads
  #============================================================================
  class ProgressOverlay
    def initialize(viewport, total_items, title = "Downloading...")
      @vp = viewport
      @total = [total_items, 1].max
      @title = title
      @cancelled = false
      @batch_installed = []  # track folders installed in this batch (for rollback)

      @dim = Sprite.new(@vp)
      @dim.bitmap = Bitmap.new(512, 384)
      @dim.bitmap.fill_rect(0, 0, 512, 384, Color.new(0, 0, 0, 140))
      @dim.z = 950

      box_w = 320
      box_h = 140
      @box = Sprite.new(@vp)
      @box.bitmap = Bitmap.new(box_w, box_h)
      @box.x = (512 - box_w) / 2
      @box.y = (384 - box_h) / 2
      @box.z = 951

      @box_w = box_w
      @box_h = box_h

      _draw_frame
    end

    def batch_installed
      @batch_installed
    end

    def add_to_batch(folder)
      @batch_installed << folder unless @batch_installed.include?(folder)
    end

    def update(item_name, item_index, file_name = nil, file_count = 0, total_files = 0)
      b = @box.bitmap
      # Clear content area (keep frame)
      b.fill_rect(12, 30, @box_w - 24, @box_h - 50, Color.new(40, 35, 60))

      pbSetSmallFont(b)
      shadow = Color.new(40, 35, 55)
      white = Color.new(255, 255, 255)
      gray = Color.new(180, 180, 180)
      dim = Color.new(120, 120, 140)
      yellow = Color.new(240, 220, 80)

      # Current item
      truncated = item_name.to_s
      truncated = truncated[0..22] + ".." if truncated.length > 24
      pbDrawShadowText(b, 16, 32, @box_w - 32, 16, truncated, white, shadow)

      # Item count
      pbDrawShadowText(b, @box_w - 16, 32, -1, 16, "(#{item_index}/#{@total})", gray, shadow, 1)

      # Progress bar
      bar_x = 16
      bar_y = 54
      bar_w = @box_w - 32
      bar_h = 16
      b.fill_rect(bar_x, bar_y, bar_w, bar_h, Color.new(25, 22, 38))
      fill_w = [(item_index.to_f / @total * bar_w).round, bar_w].min
      b.fill_rect(bar_x, bar_y, fill_w, bar_h, Color.new(100, 80, 180)) if fill_w > 0
      # Percentage
      pct = (item_index.to_f / @total * 100).round
      pbDrawShadowText(b, bar_x, bar_y - 2, bar_w, bar_h, "#{pct}%", white, shadow, 2)

      # File info (if provided)
      if file_name && total_files > 0
        file_text = "File: #{file_name} (#{file_count}/#{total_files})"
        file_text = file_text[0..38] + ".." if file_text.length > 40
        pbDrawShadowText(b, 16, 76, @box_w - 32, 16, file_text, dim, shadow)
      end

      # Cancel hint
      pbDrawShadowText(b, 0, @box_h - 26, @box_w, 16, "ESC: Cancel", yellow, shadow, 2)

      Graphics.update
      Input.update
      @cancelled = true if Input.trigger?(Input::B)
    end

    def cancelled?
      @cancelled
    end

    def dispose
      [@box, @dim].each do |s|
        next unless s
        s.bitmap.dispose rescue nil
        s.dispose rescue nil
      end
    end

    private

    def _draw_frame
      b = @box.bitmap
      # Background
      b.fill_rect(2, 0, @box_w - 4, @box_h, Color.new(40, 35, 60))
      b.fill_rect(0, 2, @box_w, @box_h - 4, Color.new(40, 35, 60))
      b.fill_rect(1, 1, @box_w - 2, @box_h - 2, Color.new(40, 35, 60))
      # Border
      b.fill_rect(2, 0, @box_w - 4, 1, Color.new(120, 100, 180))
      b.fill_rect(2, @box_h - 1, @box_w - 4, 1, Color.new(120, 100, 180))
      b.fill_rect(0, 2, 1, @box_h - 4, Color.new(120, 100, 180))
      b.fill_rect(@box_w - 1, 2, 1, @box_h - 4, Color.new(120, 100, 180))
      # Title
      pbSetSystemFont(b)
      b.font.size = 18
      pbDrawShadowText(b, 0, 6, @box_w, 20, @title, Color.new(255, 255, 255), Color.new(40, 35, 55), 2)
    end
  end

  #============================================================================
  # Browser Scene — with [Mods] [Modpacks] [Share Code] tabs
  #============================================================================
  class Scene_Browser
    # Colors
    BG_COLOR       = Color.new(20, 18, 30, 240)
    PANEL_BG       = Color.new(35, 32, 50)
    PANEL_BORDER   = Color.new(80, 70, 110)
    ROW_NORMAL     = Color.new(255, 255, 255, 8)
    ROW_SELECTED   = Color.new(255, 255, 255, 30)
    WHITE          = Color.new(255, 255, 255)
    GRAY           = Color.new(180, 180, 180)
    DIM            = Color.new(120, 120, 140)
    SHADOW         = Color.new(40, 35, 55)
    GREEN          = Color.new(100, 220, 120)
    YELLOW         = Color.new(240, 220, 80)
    BLUE           = Color.new(100, 160, 255)
    PURPLE         = Color.new(160, 120, 240)
    TAG_BG         = Color.new(60, 55, 80)
    FOOTER_BG      = Color.new(28, 25, 42)
    SEARCH_BG      = Color.new(50, 45, 70)
    TAB_ACTIVE     = Color.new(60, 50, 90)
    TAB_INACTIVE   = Color.new(35, 32, 50)

    SCREEN_W = 512
    SCREEN_H = 384
    TITLE_H  = 28
    TAB_H    = 22
    FOOTER_H = 28
    LEFT_W   = 186
    RIGHT_W  = SCREEN_W - LEFT_W - 16
    ROW_H    = 20
    SEARCH_H = 22
    CONTENT_Y = TITLE_H + TAB_H + 4
    CONTENT_H = SCREEN_H - TITLE_H - TAB_H - FOOTER_H - 8
    LIST_Y   = SEARCH_H + 4
    LIST_H   = CONTENT_H - SEARCH_H - 4

    TABS = [:mods, :modpacks, :share_code]
    TAB_LABELS = { mods: "Mods", modpacks: "Modpacks", share_code: "Share Code" }

    def initialize
      @vp = nil
      @bg = @title_spr = @tab_spr = @left_spr = @right_spr = @footer_spr = nil
      @running = false
      @active_tab = :mods
      # Mods tab state
      @remote_mods = []
      @filtered_mods = []
      # Modpacks tab state
      @remote_modpacks = []
      @filtered_modpacks = []
      @modpacks_loaded = false
      # Share code tab state
      @share_sel = 0  # 0=Export, 1=Import
      @import_code = ""
      @import_decoded = nil
      # Common state
      @sel_index = 0
      @scroll = 0
      @search_text = ""
      @search_active = false
      @filter_tag = nil
      @cursor_frame = 0
      @loading = true
      @last_drawn_sel = -1
    end

    def main
      Graphics.freeze
      setup
      Graphics.transition(8)
      loop do
        Graphics.update
        Input.update
        break unless @running
        # Blink cursor when search is active
        if @search_active
          @cursor_frame += 1
          draw_left if @cursor_frame % 20 == 0
        end
        update_background_loading if @active_tab == :mods && !@loading
        handle_input
        
        # Mouse handling
        handle_mouse

        # Description scrolling
        mx = (Input.mouse_x rescue -1) - @right_spr.x
        my = (Input.mouse_y rescue -1) - @right_spr.y
        if mx >= 0 && mx < RIGHT_W && my >= 0 && my < CONTENT_H
          mw = (Input.mouse_wheel rescue 0)
          if mw != 0
            old_scroll = @desc_scroll || 0
            @desc_scroll = [old_scroll - (mw > 0 ? 1 : -1), 0].max
            draw_right
          end
        end
      end
      Graphics.freeze
      teardown
      Graphics.transition(8)
    end

    def setup
      @running = true

      @vp = Viewport.new(0, 0, SCREEN_W, SCREEN_H)
      @vp.z = 100_000

      @bg = Sprite.new(@vp)
      @bg.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      @bg.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(20, 18, 30, 255))

      @title_spr = Sprite.new(@vp)
      @title_spr.bitmap = Bitmap.new(SCREEN_W, TITLE_H)
      @title_spr.z = 10

      @tab_spr = Sprite.new(@vp)
      @tab_spr.bitmap = Bitmap.new(SCREEN_W, TAB_H)
      @tab_spr.y = TITLE_H
      @tab_spr.z = 10

      @left_spr = Sprite.new(@vp)
      @left_spr.bitmap = Bitmap.new(LEFT_W, CONTENT_H)
      @left_spr.x = 4
      @left_spr.y = CONTENT_Y
      @left_spr.z = 10

      @right_spr = Sprite.new(@vp)
      @right_spr.bitmap = Bitmap.new(RIGHT_W, CONTENT_H)
      @right_spr.x = LEFT_W + 12
      @right_spr.y = CONTENT_Y
      @right_spr.z = 10

      @footer_spr = Sprite.new(@vp)
      @footer_spr.bitmap = Bitmap.new(SCREEN_W, FOOTER_H)
      @footer_spr.y = SCREEN_H - FOOTER_H
      @footer_spr.z = 10

      draw_title
      draw_tabs
      draw_footer
      draw_loading
      fetch_catalog
    end

    def teardown
      [@footer_spr, @right_spr, @left_spr, @tab_spr, @title_spr, @bg].compact.each do |s|
        begin
          s.bitmap.dispose if s.bitmap && !s.bitmap.disposed?
          s.dispose
        rescue; end
      end
      @vp.dispose if @vp
      @vp = nil
    end

    def draw_loading
      b = @left_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
      pbSetSystemFont(b)
      b.font.size = 16
      pbDrawShadowText(b, 0, CONTENT_H / 2 - 10, LEFT_W, 20, "Loading...", DIM, SHADOW, 2)

      b2 = @right_spr.bitmap
      b2.clear
      draw_rounded_rect(b2, 0, 0, RIGHT_W, CONTENT_H, PANEL_BG)
    end

    def draw_tabs
      b = @tab_spr.bitmap
      b.clear
      b.fill_rect(0, 0, SCREEN_W, TAB_H, FOOTER_BG)

      pbSetSmallFont(b)
      tab_w = SCREEN_W / TABS.length
      TABS.each_with_index do |tab, i|
        tx = i * tab_w
        active = (tab == @active_tab)
        bg = active ? TAB_ACTIVE : TAB_INACTIVE
        b.fill_rect(tx + 1, 0, tab_w - 2, TAB_H, bg)
        if active
          b.fill_rect(tx + 1, TAB_H - 2, tab_w - 2, 2, PURPLE)
        end
        label = TAB_LABELS[tab]
        color = active ? WHITE : DIM
        pbDrawShadowText(b, tx, 0, tab_w, TAB_H, label, color, SHADOW, 2)
      end
    end

    def fetch_catalog
      @loading = false

      # The marker check is done in Scene_Installed#open_browser BEFORE
      # this scene is ever created. This is a safety net only.
      marker = File.join(ModManager::MOD_DIR, ".mod_browser_enabled")
      unless File.exist?(marker)
        @remote_mods = []
        @filtered_mods = []
        @running = false
        return
      end

      folders = GitHub.fetch_mod_list
      folders = [] if folders.nil? || !folders.is_a?(Array)

      @remote_mods = folders.map { |f| { "folder" => f, "json" => nil } }

      # Add KIF Multiplayer as a pinned special entry at the top
      mp_version = GitHub.fetch_mp_remote_version
      if mp_version
        mp_entry = {
          "folder" => "_kif_multiplayer",
          "special" => true,
          "json" => {
            "name" => "KIF Multiplayer",
            "id" => "_kif_multiplayer",
            "version" => mp_version,
            "author" => "sKarreku",
            "description" => "The official KIF Multiplayer mod. Adds online multiplayer, EBDX battle system, boss battles, and more. This is a large download (~100 MB) that installs scripts, graphics, audio, and fonts.",
            "tags" => ["Multiplayer", "Content", "Visual", "Audio"],
            "dependencies" => [],
            "incompatible" => [],
            "settings" => [],
            "scripts" => []
          }
        }
        @remote_mods.unshift(mp_entry)
      end

      # Add Aleks Full Implementation (NPT) as a pinned special entry
      npt_entry = {
        "folder" => "_aleks_npt",
        "special" => true,
        "json" => {
          "name" => "Aleks Full Implementation",
          "id" => "_aleks_npt",
          "version" => GitHub.npt_remote_version,
          "author" => "sKarreku",
          "description" => "A massive content pack that adds custom mega forms, sprites, audio, and graphics. This is a very large download (~5 GB) that installs into Data, Audio, and Graphics folders.",
          "tags" => ["Content", "Visual", "Audio", "Fusion"],
          "dependencies" => [],
          "incompatible" => [],
          "settings" => [],
          "scripts" => []
        }
      }
      if @remote_mods.length > 0 && @remote_mods[0]["folder"] == "_kif_multiplayer"
        @remote_mods.insert(1, npt_entry)
      else
        @remote_mods.unshift(npt_entry)
      end

      if @remote_mods.empty?
        @filtered_mods = []
        b = @left_spr.bitmap
        b.clear
        draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
        pbSetSystemFont(b)
        b.font.size = 14
        pbDrawShadowText(b, 8, CONTENT_H / 2 - 20, LEFT_W - 16, 20,
                         "No mods found.", DIM, SHADOW, 2)
        pbDrawShadowText(b, 8, CONTENT_H / 2 + 4, LEFT_W - 16, 20,
                         "Press ESC to go back.", DIM, SHADOW, 2)
        draw_title
        return
      end

      @filtered_mods = @remote_mods.dup
      @sel_index = 0
      @scroll = 0
      @last_drawn_sel = -1
      draw_title
      draw_left
      draw_right
    end

    #==========================================================================
    # Drawing
    #==========================================================================
    def draw_title
      b = @title_spr.bitmap
      b.clear
      b.fill_rect(0, 0, SCREEN_W, TITLE_H, FOOTER_BG)
      pbSetSystemFont(b)
      b.font.size = 20
      pbDrawShadowText(b, 8, 0, -1, TITLE_H, "Mod Browser", WHITE, SHADOW)
      b.font.size = 16
      case @active_tab
      when :mods
        pbDrawShadowText(b, SCREEN_W - 8, 0, -1, TITLE_H,
                         "#{@filtered_mods.length} available", DIM, SHADOW, 1)
      when :modpacks
        pbDrawShadowText(b, SCREEN_W - 8, 0, -1, TITLE_H,
                         "#{@filtered_modpacks.length} packs", DIM, SHADOW, 1)
      when :share_code
        pbDrawShadowText(b, SCREEN_W - 8, 0, -1, TITLE_H,
                         "Share Codes", DIM, SHADOW, 1)
      end
    end

    def draw_left
      case @active_tab
      when :modpacks   then return draw_left_modpacks
      when :share_code then return draw_left_share_code
      end

      b = @left_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BORDER)

      # Search bar
      search_bg = @search_active ? Color.new(70, 60, 100) : SEARCH_BG
      search_border = @search_active ? Color.new(140, 120, 200) : PANEL_BORDER
      draw_rounded_rect(b, 4, 4, LEFT_W - 8, SEARCH_H, search_bg)
      if @search_active
        draw_border(b, 4, 4, LEFT_W - 8, SEARCH_H, search_border)
      end
      pbSetSmallFont(b)
      if @search_active
        cursor = (@cursor_frame / 20) % 2 == 0 ? "|" : ""
        search_display = @search_text + cursor
        search_color = WHITE
      elsif @search_text.empty?
        search_display = "Click or S to search..."
        search_color = DIM
      else
        search_display = @search_text
        search_color = WHITE
      end
      pbDrawShadowText(b, 10, 2, LEFT_W - 20, SEARCH_H, search_display, search_color, SHADOW)

      rpp = rows_per_page
      visible = @filtered_mods[@scroll, rpp] || []

      pbSetSmallFont(b)
      visible.each_with_index do |entry, i|
        real_index = @scroll + i
        y = LIST_Y + i * ROW_H
        selected = (real_index == @sel_index)
        folder = entry["folder"]

        # Row bg
        b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, selected ? ROW_SELECTED : ROW_NORMAL)

        is_special = entry["special"]

        # Badge: installed / update / restart needed
        if is_special
          if GitHub.just_installed[folder]
            pbDrawShadowText(b, LEFT_W - 62, y - 2, 56, ROW_H, "RESTART", YELLOW, SHADOW, 1)
          elsif _special_installed?(folder)
            local_v = _special_local_version(folder)
            remote_v = entry["json"] ? entry["json"]["version"] : nil
            if local_v && remote_v && ModManager.compare_versions(remote_v, local_v) > 0
              pbDrawShadowText(b, LEFT_W - 42, y - 2, 36, ROW_H, "UPD", YELLOW, SHADOW, 1)
            else
              pbDrawShadowText(b, LEFT_W - 42, y - 2, 36, ROW_H, "OK", GREEN, SHADOW, 1)
            end
          end
        else
          local = ModManager.get_mod(folder)
          if GitHub.just_installed[folder]
            pbDrawShadowText(b, LEFT_W - 62, y - 2, 56, ROW_H, "RESTART", YELLOW, SHADOW, 1)
          elsif local
            json = entry["json"]
            if json && GitHub.has_update?(folder, json)
              pbDrawShadowText(b, LEFT_W - 42, y - 2, 36, ROW_H, "UPD", YELLOW, SHADOW, 1)
            else
              pbDrawShadowText(b, LEFT_W - 42, y - 2, 36, ROW_H, "OK", GREEN, SHADOW, 1)
            end
          end
        end

        # Mod name (use folder name until json is loaded)
        json = entry["json"]
        name = json ? json["name"].to_s : folder
        name_color = is_special ? YELLOW : WHITE
        name = name[0..16] + ".." if name.length > 18
        pbDrawShadowText(b, 8, y - 2, LEFT_W - 50, ROW_H, name, name_color, SHADOW)
      end

      # Scroll indicators
      if @scroll > 0
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y - 12, -1, 12, "^", GRAY, SHADOW, 2)
      end
      if @scroll + rpp < @filtered_mods.length
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y + rpp * ROW_H - 2, -1, 12, "v", GRAY, SHADOW, 2)
      end
    end

    def draw_right
      case @active_tab
      when :modpacks   then return draw_right_modpacks
      when :share_code then return draw_right_share_code
      end

      b = @right_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BORDER)

      if @filtered_mods.empty?
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, 0, CONTENT_H / 2 - 12, RIGHT_W, 24,
                         "No mods found", DIM, SHADOW, 2)
        return
      end

      entry = @filtered_mods[@sel_index]
      return unless entry

      folder = entry["folder"]
      json = entry["json"]

      # Lazy-load mod.json on selection (only fetch once per entry)
      unless json
        json = GitHub.fetch_mod_json(folder)
        entry["json"] = json
        # Update left panel to show name instead of folder
        draw_left if json
      end

      @last_drawn_sel = @sel_index

      x = 12
      y = 8

      unless json
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, x, y, -1, 20, folder, WHITE, SHADOW)
        y += 22
        pbSetSmallFont(b)
        pbDrawShadowText(b, x, y, -1, 14, "Could not load mod info.", DIM, SHADOW)
        return
      end

      # Name
      pbSetSystemFont(b)
      b.font.size = 20
      pbDrawShadowText(b, x, y, RIGHT_W - 24, 24, json["name"].to_s, WHITE, SHADOW)
      y += 24

      # Version + Author
      pbSetSmallFont(b)
      pbDrawShadowText(b, x, y, -1, 16, "v#{json["version"]}", GRAY, SHADOW)
      pbDrawShadowText(b, x + 60, y, -1, 16, "by #{json["author"]}", GRAY, SHADOW)
      y += 18

      # Install status
      is_special = entry["special"]
      if is_special
        if GitHub.just_installed[folder]
          pbDrawShadowText(b, x, y, -1, 16, "Installed — restart the game to apply", YELLOW, SHADOW)
        elsif _special_installed?(folder)
          local_v = _special_local_version(folder)
          remote_v = json["version"]
          if local_v && remote_v && ModManager.compare_versions(remote_v, local_v) > 0
            pbDrawShadowText(b, x, y, -1, 16,
              "Update available (v#{local_v} -> v#{remote_v})", YELLOW, SHADOW)
          else
            pbDrawShadowText(b, x, y, -1, 16, "Installed (v#{local_v || '?'})", GREEN, SHADOW)
          end
        else
          pbDrawShadowText(b, x, y, -1, 16, "Not installed", BLUE, SHADOW)
        end
      else
        local = ModManager.get_mod(folder)
        if GitHub.just_installed[folder]
          pbDrawShadowText(b, x, y, -1, 16, "Installed — restart the game to apply", YELLOW, SHADOW)
        elsif local
          if GitHub.has_update?(folder, json)
            pbDrawShadowText(b, x, y, -1, 16,
              "Update available (v#{local.version} -> v#{json["version"]})", YELLOW, SHADOW)
          else
            pbDrawShadowText(b, x, y, -1, 16, "Installed (v#{local.version})", GREEN, SHADOW)
          end
        else
          pbDrawShadowText(b, x, y, -1, 16, "Not installed", BLUE, SHADOW)
        end
      end
      y += 20

      # Separator
      b.fill_rect(x, y, RIGHT_W - 24, 1, PANEL_BORDER)
      y += 6

      # Tags
      tags = json["tags"]
      if tags.is_a?(Array) && tags.length > 0
        tag_x = x
        tag_h = 18
        tags.each do |tag|
          tw = b.text_size(tag.to_s).width + 10
          if tag_x + tw > RIGHT_W - 12
            tag_x = x
            y += tag_h + 2
          end
          draw_rounded_rect(b, tag_x, y, tw, tag_h, TAG_BG)
          pbDrawShadowText(b, tag_x + 5, y - 4, tw, tag_h, tag.to_s, GRAY, SHADOW)
          tag_x += tw + 4
        end
        y += tag_h + 6
      end

      # Description — scrollable
      hint_y = CONTENT_H - 22
      desc = _get_description(json)
      start_y = y # Capture for scrollbar
      unless desc.empty?
        max_desc_y = hint_y - 4
        pbSetSmallFont(b)
        
        # Split description into lines that fit the width, respecting \n
        desc_lines = []
        desc.split("\n").each do |raw_line|
          words = raw_line.split(" ")
          if words.empty?
            desc_lines << "" # Empty line from double newline
            next
          end
          current = ""
          words.each do |word|
            test = current.empty? ? word : "#{current} #{word}"
            if b.text_size(test).width > RIGHT_W - 28
              desc_lines << current
              current = word
            else
              current = test
            end
          end
          desc_lines << current unless current.empty?
        end
        
        # Draw visible description lines
        @desc_scroll = 0 if @desc_scroll.nil?
        max_visible_desc = (max_desc_y - start_y) / 14 # use start_y from before loop
        max_scroll = [desc_lines.length - max_visible_desc, 0].max
        @desc_scroll = @desc_scroll.clamp(0, max_scroll)
        
        desc_lines.each_with_index do |line, i|
          next if i < @desc_scroll
          break if i >= @desc_scroll + max_visible_desc
          pbDrawShadowText(b, x, start_y + (i - @desc_scroll) * 15, RIGHT_W - 28, 14, line, GRAY, SHADOW)
        end

        # Scrollbar
        if desc_lines.length > max_visible_desc
          sb_x = RIGHT_W - 14
          sb_y = start_y
          sb_h = max_desc_y - sb_y
          b.fill_rect(sb_x, sb_y, 10, sb_h, Color.new(0, 0, 0, 60))
          
          handle_h = [ (sb_h.to_f * max_visible_desc / desc_lines.length).to_i, 16].max
          
          if @dragging_desc
            rmy = (Input.mouse_y rescue 0) - @right_spr.y
            ratio = (rmy - sb_y).to_f / sb_h
            @desc_scroll = (desc_lines.length * ratio - max_visible_desc / 2).to_i.clamp(0, max_scroll)
          end

          handle_y = sb_y + (sb_h - handle_h) * @desc_scroll.to_f / max_scroll
          b.fill_rect(sb_x + 1, handle_y, 8, handle_h, GRAY)
          @desc_scrollbar_rect = Rect.new(sb_x, sb_y, 10, sb_h)
        else
          @desc_scrollbar_rect = nil
          @desc_scroll = 0
        end
        # Ensure y doesn't overflow to dependencies if too long
        y = [y, max_desc_y].min
      end

      # Dependencies
      deps = json["dependencies"]
      if deps.is_a?(Array) && deps.length > 0 && y + 16 < hint_y
        y += 4
        dep_names = deps.map { |d| d.is_a?(Hash) ? d["id"].to_s : d.to_s }.join(", ")
        pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, "Requires: #{dep_names}", YELLOW, SHADOW)
        y += 14
      end

      # Action hint
      if GitHub.just_installed[folder]
        pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Restart required", YELLOW, SHADOW, 2)
      elsif is_special
        if _special_installed?(folder)
          local_v = _special_local_version(folder)
          remote_v = json["version"]
          if local_v && remote_v && ModManager.compare_versions(remote_v, local_v) > 0
            pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Update  |  X: Back", DIM, SHADOW, 2)
          else
            pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Already installed  |  X: Back", DIM, SHADOW, 2)
          end
        else
          size_hint = (folder == "_kif_multiplayer") ? "~100 MB" : "~5 GB"
          pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Install (#{size_hint})  |  X: Back", DIM, SHADOW, 2)
        end
      elsif local
        if GitHub.has_update?(folder, json)
          pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Update  |  X: Back", DIM, SHADOW, 2)
        else
          pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Already installed  |  X: Back", DIM, SHADOW, 2)
        end
      else
        pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Install  |  X: Back", DIM, SHADOW, 2)
      end
    end

    def draw_footer
      b = @footer_spr.bitmap
      b.clear
      b.fill_rect(0, 0, SCREEN_W, FOOTER_H, FOOTER_BG)
      pbSetSmallFont(b)

      case @active_tab
      when :mods, :modpacks
        tag_text = @filter_tag ? "T: Tag [#{@filter_tag}]" : "T: Filter by Tag"
        pbDrawShadowText(b, 8, 0, -1, FOOTER_H, "S: Search  |  #{tag_text}  |  Tab: Switch", DIM, SHADOW)
      when :share_code
        pbDrawShadowText(b, 8, 0, -1, FOOTER_H, "Tab: Switch  |  Ctrl+V: Paste", DIM, SHADOW)
      end
      pbDrawShadowText(b, SCREEN_W - 8, 0, -1, FOOTER_H, "X: Back", DIM, SHADOW, 1)
    end

    def update_background_loading
      return if @loading || @filtered_mods.empty?
      
      # Find first entry without json loaded
      # We prioritize visible entries first
      rpp = rows_per_page
      visible_indices = (@scroll...(@scroll + rpp)).to_a
      other_indices = (0...@filtered_mods.length).to_a - visible_indices
      
      target_index = (visible_indices + other_indices).find { |idx| @filtered_mods[idx] && @filtered_mods[idx]["json"].nil? }
      
      if target_index
        entry = @filtered_mods[target_index]
        folder = entry["folder"]
        json = GitHub.fetch_mod_json(folder)
        if json
          entry["json"] = json
          draw_left
          draw_right if target_index == @sel_index
        end
      end
    end

    #==========================================================================
    # Input
    #==========================================================================
    def handle_input
      # Mouse handling every frame
      handle_mouse

      # Search active — capture keyboard (mods/modpacks tabs only)
      if @search_active && @active_tab != :share_code
        handle_search_input
        return
      end

      # Back
      if Input.trigger?(Input::B) || Input.trigger?(Input::MOUSERIGHT)
        @running = false
        return
      end

      # Tab switching: Tab key cycles, 1/2/3 keys
      if _key_trigger?(0x09)  # Tab
        switch_tab(TABS[(TABS.index(@active_tab) + 1) % TABS.length])
        return
      end
      if _key_trigger?(0x31); switch_tab(:mods); return; end       # 1
      if _key_trigger?(0x32); switch_tab(:modpacks); return; end   # 2
      if _key_trigger?(0x33); switch_tab(:share_code); return; end # 3

      case @active_tab
      when :mods     then handle_input_mods
      when :modpacks then handle_input_modpacks
      when :share_code then handle_input_share_code
      end
    end

    def handle_input_mods
      # Activate search (S key)
      if _key_trigger?(0x53)
        activate_search
        return
      end

      # Tag filter (T key)
      if _key_trigger?(0x54)
        cycle_tag_filter
        return
      end

      return if @filtered_mods.empty?

      changed = false

      if Input.repeat?(Input::UP)
        @sel_index = (@sel_index - 1) % @filtered_mods.length
        ensure_visible
        changed = true
      elsif Input.repeat?(Input::DOWN)
        @sel_index = (@sel_index + 1) % @filtered_mods.length
        ensure_visible
        changed = true
      end

      # Install / Update
      if Input.trigger?(Input::C) && @filtered_mods[@sel_index]
        do_install_or_update
        return
      end

      if changed
        draw_left
        draw_right
      end
    end

    def handle_input_modpacks
      # Load modpacks on first visit
      unless @modpacks_loaded
        fetch_modpacks
        return
      end

      # Search (S key)
      if _key_trigger?(0x53)
        activate_search
        return
      end

      # Tag filter (T key)
      if _key_trigger?(0x54)
        cycle_tag_filter_modpacks
        return
      end

      return if @filtered_modpacks.empty?

      changed = false

      if Input.repeat?(Input::UP)
        @sel_index = (@sel_index - 1) % @filtered_modpacks.length
        ensure_visible_modpacks
        changed = true
      elsif Input.repeat?(Input::DOWN)
        @sel_index = (@sel_index + 1) % @filtered_modpacks.length
        ensure_visible_modpacks
        changed = true
      end

      # Install modpack
      if Input.trigger?(Input::C) && @filtered_modpacks[@sel_index]
        do_install_modpack
        return
      end

      if changed
        draw_left
        draw_right
      end
    end

    def handle_input_share_code
      changed = false

      if Input.repeat?(Input::UP)
        @share_sel = (@share_sel - 1) % 2
        changed = true
      elsif Input.repeat?(Input::DOWN)
        @share_sel = (@share_sel + 1) % 2
        changed = true
      end

      if Input.trigger?(Input::C)
        if @share_sel == 0
          do_export_share_code
        else
          do_import_share_code
        end
        return
      end

      if changed
        draw_left
        draw_right
      end
    end

    #==========================================================================
    # Mouse
    #==========================================================================
    def handle_mouse
      mx = Input.mouse_x rescue nil
      my = Input.mouse_y rescue nil
      return unless mx && my

      clicked = Input.trigger?(Input::MOUSELEFT) rescue false
      old_sel = @sel_index

      # Tab bar click
      if clicked && my >= TITLE_H && my < TITLE_H + TAB_H
        tab_w = SCREEN_W / TABS.length
        tab_idx = (mx / tab_w).floor
        if tab_idx >= 0 && tab_idx < TABS.length
          switch_tab(TABS[tab_idx])
          return
        end
      end

      # Left panel hit test
      lx = @left_spr.x
      ly = @left_spr.y

      if @active_tab == :share_code
        # Share code: only 2 rows
        if mx >= lx && mx < lx + LEFT_W && my >= ly + 8 && my < ly + 8 + 2 * ROW_H
          row = ((my - ly - 8) / ROW_H).floor
          if row >= 0 && row < 2
            @share_sel = row
            if clicked
              if @share_sel == 0
                do_export_share_code
              else
                do_import_share_code
              end
              return
            end
          end
        end
      else
        current_list = @active_tab == :modpacks ? @filtered_modpacks : @filtered_mods
        if mx >= lx && mx < lx + LEFT_W && my >= ly + LIST_Y && my < ly + LIST_Y + LIST_H
          row = ((my - ly - LIST_Y) / ROW_H).floor
          real_index = @scroll + row
          if real_index >= 0 && real_index < current_list.length
            @sel_index = real_index
            if clicked
              if @active_tab == :modpacks
                do_install_modpack
              else
                do_install_or_update
              end
              return
            end
          end
        end

        # Search bar click
        if clicked && mx >= lx && mx < lx + LEFT_W && my >= ly && my < ly + SEARCH_H
          activate_search unless @search_active
          return
        end

        # Click outside search bar deactivates search
        if clicked && @search_active
          deactivate_search
        end
      end

      # Right panel hit test
      rx = @right_spr.x; ry = @right_spr.y
      if mx >= rx && mx < rx + RIGHT_W && my >= ry && my < ry + CONTENT_H
        # Scrollbar dragging
        if @desc_scrollbar_rect && clicked && mx >= rx + @desc_scrollbar_rect.x && mx < rx + @desc_scrollbar_rect.x + @desc_scrollbar_rect.width &&
           my >= ry + @desc_scrollbar_rect.y && my < ry + @desc_scrollbar_rect.y + @desc_scrollbar_rect.height
          @dragging_desc = true
        end
      end

      if @dragging_desc
        if !Input.press?(Input::MOUSELEFT)
          @dragging_desc = false
        else
          draw_right
        end
      end

      # Redraw only if selection changed or dragging
      if @sel_index != old_sel || @share_sel != (@share_sel_prev || 0) || @dragging_desc
        @share_sel_prev = @share_sel
        draw_left
        draw_right
      end
    end

    #==========================================================================
    # Live Search
    #==========================================================================
    def activate_search
      @search_active = true
      @cursor_frame = 0
      draw_left
    end

    def deactivate_search
      @search_active = false
      draw_left
    end

    def handle_search_input
      # ESC / Enter / Right-click — close search
      if Input.trigger?(Input::B) || _key_trigger?(0x0D) || Input.trigger?(Input::MOUSERIGHT)
        deactivate_search
        return
      end

      old_text = @search_text

      # Backspace
      if _key_repeat?(0x08)
        @search_text = @search_text[0...-1] unless @search_text.empty?
      end

      # Delete all
      if _key_trigger?(0x2E)
        @search_text = ""
      end

      # A-Z
      (0x41..0x5A).each do |vk|
        if _key_trigger?(vk)
          shift = _key_pressed?(0x10)
          ch = (vk - 0x41 + 97).chr
          ch = ch.upcase if shift
          @search_text += ch if @search_text.length < 30
        end
      end

      # 0-9
      (0x30..0x39).each do |vk|
        if _key_trigger?(vk)
          @search_text += (vk - 0x30).to_s if @search_text.length < 30
        end
      end

      # Space
      if _key_trigger?(0x20)
        @search_text += " " if @search_text.length < 30
      end

      # Minus / underscore
      if _key_trigger?(0xBD)
        shift = _key_pressed?(0x10)
        @search_text += (shift ? "_" : "-") if @search_text.length < 30
      end

      # Re-filter if text changed
      if @search_text != old_text
        @sel_index = 0
        @scroll = 0
        @last_drawn_sel = -1
        if @active_tab == :modpacks
          apply_filter_modpacks
        else
          apply_filter
        end
        draw_title
        draw_left
        draw_right
      end
    end

    #==========================================================================
    # Actions
    #==========================================================================
    def do_install_or_update
      return if @filtered_mods.empty?
      entry = @filtered_mods[@sel_index]
      return unless entry

      # Special handling for pinned entries
      if entry["special"]
        if entry["folder"] == "_kif_multiplayer"
          do_install_multiplayer(entry)
        elsif entry["folder"] == "_aleks_npt"
          do_install_npt(entry)
        end
        return
      end

      folder = entry["folder"]
      json = entry["json"] || GitHub.fetch_mod_json(folder)
      entry["json"] = json

      local = ModManager.get_mod(folder)
      if local && json && !GitHub.has_update?(folder, json)
        show_message("#{json["name"] || folder} is already up to date.")
      else
        action = local ? "Update" : "Install"
        name = json ? json["name"].to_s : folder

        # Resolve dependencies
        dep_result = ModManager.resolve_all_dependencies(folder)
        deps_to_install = dep_result["to_install"] - [folder]
        deps_missing = dep_result["missing"]

        # Show deps info in confirmation
        confirm_msg = "#{action} #{name}?"
        unless deps_to_install.empty?
          confirm_msg += "\n\n#{deps_to_install.length} dependency/ies will\nalso be installed."
        end

        if show_message(confirm_msg, ["Yes", "No"]) == 0
          # Warn about missing deps
          unless deps_missing.empty?
            show_message("Warning: Missing dependencies\n(not on GitHub):\n#{deps_missing.join(', ')}\n\nMod may not work correctly.")
          end

          # Build download list (deps first, then main mod)
          download_list = deps_to_install + [folder]

          if download_list.length == 1
            # Single mod — simple flow
            show_status("Downloading #{name}...")
            if GitHub.download_mod(folder)
              ModManager.refresh
              GitHub.mark_installed(folder)
              hide_status
              show_message("#{name} installed!\nRestart the game to apply.")
            else
              hide_status
              show_message("Download failed.\nCheck your internet connection.")
            end
          else
            # Multiple mods — use progress overlay
            overlay = ProgressOverlay.new(@vp, download_list.length, "Installing #{name}...")
            download_list.each_with_index do |mid, i|
              mod_json = GitHub.fetch_mod_json(mid)
              mod_name = mod_json ? mod_json["name"].to_s : mid
              overlay.update(mod_name, i, nil, 0, 0)

              if overlay.cancelled?
                _handle_cancel(overlay)
                draw_left
                draw_right
                return
              end

              if GitHub.download_mod(mid)
                ModManager.refresh
                GitHub.mark_installed(mid)
                overlay.add_to_batch(mid)
              end
            end
            overlay.update("Done!", download_list.length)
            overlay.dispose
            show_message("#{name} and #{deps_to_install.length}\ndependency/ies installed!\nRestart the game to apply.")
          end
        end
      end
      draw_left
      draw_right
    end

    def do_install_multiplayer(entry)
      json = entry["json"]
      remote_v = json["version"]
      folder = entry["folder"]

      # Check if already installed and up to date
      if GitHub.mp_installed?
        local_v = GitHub.mp_local_version
        if local_v && ModManager.compare_versions(remote_v, local_v) <= 0
          show_message("KIF Multiplayer is already up to date.\n(v#{local_v})")
          return
        end
        action = "Update"
        detail = "v#{local_v} -> v#{remote_v}"
      else
        action = "Install"
        detail = "v#{remote_v}"
      end

      result = show_message(
        "#{action} KIF Multiplayer #{detail}?\n\nThis is a large download (~100 MB).\nA terminal window will open to handle\nthe download and installation.",
        ["Yes", "No"]
      )
      return unless result == 0

      # Find the install script (use absolute paths)
      game_root = File.expand_path(".")
      script_dir = File.join(game_root, "ModDev")

      if RUBY_PLATFORM =~ /mingw|mswin|cygwin/i || (ENV['OS'] =~ /windows/i rescue false)
        script = File.join(script_dir, "install_multiplayer.bat")
        if File.exist?(script)
          _launch_bat("KIF Multiplayer Installer", script, [remote_v, GitHub.mp_archive_url(remote_v), game_root])
        else
          show_message("Install script not found:\n#{script}")
          return
        end
      else
        script = File.join(script_dir, "install_multiplayer.sh")
        if File.exist?(script)
          system("chmod +x \"#{script}\"") rescue nil
          if ENV['TERM_PROGRAM'] || ENV['TERMINAL_EMULATOR']
            Process.spawn("bash", script, remote_v, GitHub.mp_archive_url(remote_v), game_root)
          elsif system("which gnome-terminal > /dev/null 2>&1")
            Process.spawn("gnome-terminal", "--", "bash", script, remote_v, GitHub.mp_archive_url(remote_v), game_root)
          elsif system("which xterm > /dev/null 2>&1")
            Process.spawn("xterm", "-e", "bash", script, remote_v, GitHub.mp_archive_url(remote_v), game_root)
          else
            Process.spawn("bash", script, remote_v, GitHub.mp_archive_url(remote_v), game_root)
          end
        else
          show_message("Install script not found:\n#{script}")
          return
        end
      end

      GitHub.mark_installed(folder)
      show_message("The installer is running in a separate\nwindow. Restart the game when it finishes.")
      draw_left
      draw_right
    end

    def do_install_npt(entry)
      json = entry["json"]
      remote_v = json["version"]
      folder = entry["folder"]

      if remote_v.nil?
        show_message("Could not check for AFI updates.\nPlease check your internet connection.")
        return
      end

      if GitHub.npt_installed?
        local_v = GitHub.npt_local_version
        if local_v && ModManager.compare_versions(remote_v, local_v) <= 0
          show_message("Aleks Full Implementation is already\nup to date. (v#{local_v})")
          return
        end
        is_update = true
        detail = "v#{local_v} -> v#{remote_v}"
      else
        is_update = false
        detail = "v#{remote_v}"
      end

      # Determine install mode
      if is_update
        # Update: let user choose code-only or full
        code_size = GitHub.npt_code_size
        assets_size = GitHub.npt_assets_size
        code_label = code_size ? "(~#{'%.1f' % (code_size / 1048576.0)} MB)" : ""
        assets_label = assets_size ? "(~#{'%.1f' % (assets_size / 1073741824.0)} GB)" : ""

        result = show_message(
          "Update AFI #{detail}?\n\nChoose what to download:",
          ["Code only #{code_label}", "Full (code + sprites) #{assets_label}", "Cancel"]
        )
        return if result == 2 || result < 0
        install_mode = result == 0 ? "code" : "full"
      else
        # First install: always full
        assets_size = GitHub.npt_assets_size
        size_label = assets_size ? "~#{'%.1f' % (assets_size / 1073741824.0)} GB" : "~10 GB"
        result = show_message(
          "Install Aleks Full Implementation #{detail}?\n\nThis is a large download (#{size_label}).\nA terminal window will open to handle\nthe download and installation.",
          ["Yes", "No"]
        )
        return unless result == 0
        install_mode = "full"
      end

      game_root = File.expand_path(".")
      script_dir = File.join(game_root, "ModDev")

      if RUBY_PLATFORM =~ /mingw|mswin|cygwin/i || (ENV['OS'] =~ /windows/i rescue false)
        script = File.join(script_dir, "install_npt.bat")
        if File.exist?(script)
          _launch_bat("Aleks NPT Installer", script, [remote_v, install_mode, game_root])
        else
          show_message("Install script not found:\n#{script}")
          return
        end
      else
        script = File.join(script_dir, "install_npt.sh")
        if File.exist?(script)
          system("chmod +x \"#{script}\"") rescue nil
          if ENV['TERM_PROGRAM'] || ENV['TERMINAL_EMULATOR']
            Process.spawn("bash", script, remote_v, install_mode, game_root)
          elsif system("which gnome-terminal > /dev/null 2>&1")
            Process.spawn("gnome-terminal", "--", "bash", script, remote_v, install_mode, game_root)
          elsif system("which xterm > /dev/null 2>&1")
            Process.spawn("xterm", "-e", "bash", script, remote_v, install_mode, game_root)
          else
            Process.spawn("bash", script, remote_v, install_mode, game_root)
          end
        else
          show_message("Install script not found:\n#{script}")
          return
        end
      end

      GitHub.mark_installed(folder)
      show_message("The installer is running in a separate\nwindow. Restart the game when it finishes.")
      draw_left
      draw_right
    end

    #==========================================================================
    # Tab switching
    #==========================================================================
    def switch_tab(new_tab)
      return if new_tab == @active_tab
      @active_tab = new_tab
      @sel_index = 0
      @scroll = 0
      @search_text = ""
      @search_active = false
      @filter_tag = nil
      @last_drawn_sel = -1
      draw_tabs
      draw_title
      draw_footer
      if new_tab == :modpacks && !@modpacks_loaded
        draw_loading
        fetch_modpacks
      else
        draw_left
        draw_right
      end
    end

    #==========================================================================
    # Modpack fetching and display
    #==========================================================================
    def fetch_modpacks
      @modpacks_loaded = true
      folders = GitHub.fetch_modpack_list
      folders = [] if folders.nil? || !folders.is_a?(Array)
      @remote_modpacks = folders.map { |f| { "folder" => f, "json" => nil } }
      @filtered_modpacks = @remote_modpacks.dup

      if @remote_modpacks.empty?
        b = @left_spr.bitmap
        b.clear
        draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
        pbSetSystemFont(b)
        b.font.size = 14
        pbDrawShadowText(b, 8, CONTENT_H / 2 - 10, LEFT_W - 16, 20,
                         "No modpacks found.", DIM, SHADOW, 2)
        draw_title
        return
      end

      draw_title
      draw_left
      draw_right
    end

    def draw_left_modpacks
      b = @left_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BORDER)

      # Search bar
      search_bg = @search_active ? Color.new(70, 60, 100) : SEARCH_BG
      draw_rounded_rect(b, 4, 4, LEFT_W - 8, SEARCH_H, search_bg)
      pbSetSmallFont(b)
      if @search_active
        cursor = (@cursor_frame / 20) % 2 == 0 ? "|" : ""
        pbDrawShadowText(b, 10, 2, LEFT_W - 20, SEARCH_H, @search_text + cursor, WHITE, SHADOW)
      elsif @search_text.empty?
        pbDrawShadowText(b, 10, 2, LEFT_W - 20, SEARCH_H, "Click or S to search...", DIM, SHADOW)
      else
        pbDrawShadowText(b, 10, 2, LEFT_W - 20, SEARCH_H, @search_text, WHITE, SHADOW)
      end

      rpp = rows_per_page
      visible = @filtered_modpacks[@scroll, rpp] || []

      pbSetSmallFont(b)
      visible.each_with_index do |entry, i|
        real_index = @scroll + i
        y = LIST_Y + i * ROW_H
        selected = (real_index == @sel_index)
        b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, selected ? ROW_SELECTED : ROW_NORMAL)

        json = entry["json"]
        name = json ? json["name"].to_s : entry["folder"]
        name = name[0..16] + ".." if name.length > 18
        pbDrawShadowText(b, 8, y - 2, LEFT_W - 16, ROW_H, name, PURPLE, SHADOW)
      end

      # Scroll indicators
      if @scroll > 0
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y - 12, -1, 12, "^", GRAY, SHADOW, 2)
      end
      if @scroll + rpp < @filtered_modpacks.length
        pbDrawShadowText(b, LEFT_W / 2, LIST_Y + rpp * ROW_H - 2, -1, 12, "v", GRAY, SHADOW, 2)
      end
    end

    def draw_right_modpacks
      b = @right_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BORDER)

      if @filtered_modpacks.empty?
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, 0, CONTENT_H / 2 - 12, RIGHT_W, 24,
                         "No modpacks found", DIM, SHADOW, 2)
        return
      end

      entry = @filtered_modpacks[@sel_index]
      return unless entry

      folder = entry["folder"]
      json = entry["json"]

      unless json
        json = GitHub.fetch_modpack_json(folder)
        entry["json"] = json
        draw_left if json
      end

      x = 12
      y = 8

      unless json
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, x, y, -1, 20, folder, WHITE, SHADOW)
        y += 22
        pbSetSmallFont(b)
        pbDrawShadowText(b, x, y, -1, 14, "Could not load modpack info.", DIM, SHADOW)
        return
      end

      # Name
      pbSetSystemFont(b)
      b.font.size = 20
      pbDrawShadowText(b, x, y, RIGHT_W - 24, 24, json["name"].to_s, PURPLE, SHADOW)
      y += 24

      # Version + Author
      pbSetSmallFont(b)
      pbDrawShadowText(b, x, y, -1, 16, "v#{json["version"]}", GRAY, SHADOW)
      pbDrawShadowText(b, x + 60, y, -1, 16, "by #{json["author"]}", GRAY, SHADOW)
      y += 20

      # Description
      desc = _get_description(json)
      unless desc.empty?
        words = desc.split(" ")
        current = ""
        words.each do |word|
          test = current.empty? ? word : "#{current} #{word}"
          if b.text_size(test).width > RIGHT_W - 28
            pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, current, GRAY, SHADOW)
            y += 14
            current = word
          else
            current = test
          end
        end
        pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, current, GRAY, SHADOW) unless current.empty?
        y += 18
      end

      # Separator
      b.fill_rect(x, y, RIGHT_W - 24, 1, PANEL_BORDER)
      y += 6

      # Tags
      tags = json["tags"]
      if tags.is_a?(Array) && tags.length > 0
        tag_x = x
        tags.each do |tag|
          tw = b.text_size(tag.to_s).width + 10
          if tag_x + tw > RIGHT_W - 12
            tag_x = x
            y += 20
          end
          draw_rounded_rect(b, tag_x, y, tw, 18, TAG_BG)
          pbDrawShadowText(b, tag_x + 5, y - 4, tw, 18, tag.to_s, GRAY, SHADOW)
          tag_x += tw + 4
        end
        y += 22
      end

      # Separator
      b.fill_rect(x, y, RIGHT_W - 24, 1, PANEL_BORDER)
      y += 6

      # Mod list
      mods = json["mods"]
      if mods.is_a?(Array) && mods.length > 0
        pbDrawShadowText(b, x, y, -1, 16, "Contains #{mods.length} mod(s):", WHITE, SHADOW)
        y += 18
        mods.each do |m|
          break if y + 14 > CONTENT_H - 30
          mid = m.is_a?(Hash) ? m["id"].to_s : m.to_s
          mver = m.is_a?(Hash) ? m["version"].to_s : ""
          local = ModManager.get_mod(mid)
          if local
            if !mver.empty? && ModManager.compare_versions(local.version, mver) < 0
              status_color = YELLOW
              status_text = "v#{local.version} (needs #{mver}+)"
            else
              status_color = GREEN
              status_text = "installed"
            end
          else
            status_color = BLUE
            status_text = "not installed"
          end
          label = mver.empty? ? mid : "#{mid} v#{mver}"
          label = label[0..22] + ".." if label.length > 24
          pbDrawShadowText(b, x + 4, y, RIGHT_W / 2 - 16, 14, label, WHITE, SHADOW)
          pbDrawShadowText(b, RIGHT_W / 2, y, RIGHT_W / 2 - 16, 14, status_text, status_color, SHADOW, 2)
          y += 14
        end
      end

      # Action hint
      hint_y = CONTENT_H - 22
      pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Install All  |  X: Back", DIM, SHADOW, 2)
    end

    def do_install_modpack
      return if @filtered_modpacks.empty?
      entry = @filtered_modpacks[@sel_index]
      return unless entry

      json = entry["json"] || GitHub.fetch_modpack_json(entry["folder"])
      entry["json"] = json
      return unless json

      mods = json["mods"]
      return unless mods.is_a?(Array) && mods.length > 0

      # Build download list (skip up-to-date installed mods)
      to_download = []
      to_update = []
      up_to_date = []
      mods.each do |m|
        mid = m.is_a?(Hash) ? m["id"].to_s : m.to_s
        mver = m.is_a?(Hash) ? m["version"].to_s : ""
        local = ModManager.get_mod(mid)
        if local
          if !mver.empty? && ModManager.compare_versions(local.version, mver) < 0
            to_update << mid
          else
            up_to_date << mid
          end
        else
          to_download << mid
        end
      end

      if to_download.empty? && to_update.empty?
        show_message("All mods in this pack are already\ninstalled and up to date.")
        return
      end

      # Also resolve dependencies for all mods
      all_deps_to_install = []
      all_deps_missing = []
      (to_download + to_update).each do |mid|
        result = ModManager.resolve_all_dependencies(mid)
        all_deps_to_install.concat(result["to_install"])
        all_deps_missing.concat(result["missing"])
      end
      all_deps_to_install.uniq!
      all_deps_to_install -= (to_download + to_update + up_to_date)
      all_deps_missing.uniq!
      all_deps_missing -= (to_download + to_update + up_to_date + all_deps_to_install)

      # Build final download list (deps first, then mods)
      download_list = all_deps_to_install + to_download + to_update

      summary = "Install #{json["name"]}?\n\n"
      summary += "#{to_download.length} new, #{to_update.length} update"
      summary += ", #{up_to_date.length} skip" unless up_to_date.empty?
      summary += "\n#{all_deps_to_install.length} dependencies" unless all_deps_to_install.empty?
      if show_message(summary, ["Install All", "Cancel"]) != 0
        return
      end

      # Warn about missing deps
      unless all_deps_missing.empty?
        show_message("Warning: Missing dependencies\n(not on GitHub):\n#{all_deps_missing.join(', ')}\n\nSome mods may not work correctly.")
      end

      # Batch download with progress overlay
      overlay = ProgressOverlay.new(@vp, download_list.length, "Installing modpack...")
      download_list.each_with_index do |mid, i|
        mod_json = GitHub.fetch_mod_json(mid)
        mod_name = mod_json ? mod_json["name"].to_s : mid
        overlay.update(mod_name, i, nil, 0, 0)

        if overlay.cancelled?
          _handle_cancel(overlay)
          return
        end

        if GitHub.download_mod(mid)
          ModManager.refresh
          GitHub.mark_installed(mid)
          overlay.add_to_batch(mid)
        end
      end
      overlay.update("Done!", download_list.length)
      overlay.dispose

      show_message("#{json["name"]} installed!\n#{download_list.length} mod(s) downloaded.\nRestart the game to apply.")
      draw_left
      draw_right
    end

    #==========================================================================
    # Share Code tab
    #==========================================================================
    def draw_left_share_code
      b = @left_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, LEFT_W, CONTENT_H, PANEL_BORDER)

      pbSetSmallFont(b)
      options = ["Export Share Code", "Import Share Code"]
      options.each_with_index do |label, i|
        y = 8 + i * ROW_H
        selected = (i == @share_sel)
        b.fill_rect(4, y, LEFT_W - 8, ROW_H - 2, selected ? ROW_SELECTED : ROW_NORMAL)
        color = selected ? WHITE : GRAY
        pbDrawShadowText(b, 10, y - 2, LEFT_W - 20, ROW_H, label, color, SHADOW)
      end
    end

    def draw_right_share_code
      b = @right_spr.bitmap
      b.clear
      draw_rounded_rect(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BG)
      draw_border(b, 0, 0, RIGHT_W, CONTENT_H, PANEL_BORDER)

      x = 12
      y = 8

      if @share_sel == 0
        # Export
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, x, y, -1, 22, "Export Share Code", PURPLE, SHADOW)
        y += 28

        pbSetSmallFont(b)
        enabled = ModManager.enabled_mods
        installed = enabled.map { |id| ModManager.get_mod(id) }.compact
        if installed.empty?
          pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, "No enabled mods to export.", DIM, SHADOW)
        else
          pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, "#{installed.length} enabled mod(s):", GRAY, SHADOW)
          y += 16
          installed.each do |info|
            break if y + 14 > CONTENT_H - 40
            pbDrawShadowText(b, x + 4, y, -1, 14, "#{info.name} v#{info.version}", WHITE, SHADOW)
            y += 14
          end

          hint_y = CONTENT_H - 22
          pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "Z: Generate & Copy Code", DIM, SHADOW, 2)
        end
      else
        # Import
        pbSetSystemFont(b)
        b.font.size = 18
        pbDrawShadowText(b, x, y, -1, 22, "Import Share Code", PURPLE, SHADOW)
        y += 28

        pbSetSmallFont(b)
        pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, "Press Z to paste from clipboard", GRAY, SHADOW)
        y += 16
        pbDrawShadowText(b, x, y, RIGHT_W - 24, 14, "or enter a KIF-xxxx code.", GRAY, SHADOW)
        y += 24

        if @import_decoded
          pbDrawShadowText(b, x, y, -1, 14, "Decoded #{@import_decoded.length} mod(s):", WHITE, SHADOW)
          y += 16
          @import_decoded.each do |entry|
            break if y + 14 > CONTENT_H - 40
            mid = entry["id"]
            mver = entry["version"]
            local = ModManager.get_mod(mid)
            if local
              if !mver.empty? && ModManager.compare_versions(local.version, mver) < 0
                status = "update"
                sc = YELLOW
              else
                status = "installed"
                sc = GREEN
              end
            else
              status = "new"
              sc = BLUE
            end
            label = mver.empty? ? mid : "#{mid} v#{mver}"
            label = label[0..22] + ".." if label.length > 24
            pbDrawShadowText(b, x + 4, y, -1, 14, label, WHITE, SHADOW)
            pbDrawShadowText(b, RIGHT_W - 16, y, -1, 14, status, sc, SHADOW, 1)
            y += 14
          end
          hint_y = CONTENT_H - 22
          pbDrawShadowText(b, x, hint_y, RIGHT_W - 24, 14, "C: Install Missing  |  X: Back", DIM, SHADOW, 2)
        end
      end
    end

    def do_export_share_code
      enabled = ModManager.enabled_mods
      installed = enabled.map { |id| ModManager.get_mod(id) }.compact
      if installed.empty?
        show_message("No enabled mods to export.")
        return
      end

      entries = installed.map { |info| { "id" => info.id, "version" => info.version } }
      code = ModManager.encode_share_code(entries)
      if code
        if ModManager.clipboard_write(code)
          show_message("Share code copied to clipboard!\n\n#{code}")
        else
          show_message("Share code generated:\n\n#{code}\n\n(Could not copy to clipboard)")
        end
      else
        show_message("Failed to generate share code.")
      end
    end

    def do_import_share_code
      # Try clipboard first
      clip = ModManager.clipboard_read
      code = nil
      if clip && clip.is_a?(String) && (clip.strip.start_with?("KIF-") || clip.strip.start_with?("KIFr-"))
        code = clip.strip
      end

      unless code
        # Fallback: text input
        code = _text_input("Enter share code:", 200)
        return if code.nil? || code.empty?
      end

      decoded = ModManager.decode_share_code(code)
      if decoded.nil? || decoded.empty?
        show_message("Invalid share code.\nCodes start with KIF-")
        return
      end

      @import_decoded = decoded
      draw_right

      # Build download list
      to_download = []
      to_update = []
      decoded.each do |entry|
        mid = entry["id"]
        mver = entry["version"]
        local = ModManager.get_mod(mid)
        if local
          if !mver.empty? && ModManager.compare_versions(local.version, mver) < 0
            to_update << mid
          end
        else
          to_download << mid
        end
      end

      if to_download.empty? && to_update.empty?
        show_message("All mods in this code are already\ninstalled and up to date.")
        return
      end

      download_list = to_download + to_update
      result = show_message(
        "Install #{to_download.length} new,\nupdate #{to_update.length} mod(s)?",
        ["Install", "Cancel"]
      )
      return if result != 0

      # Batch download
      overlay = ProgressOverlay.new(@vp, download_list.length, "Installing from code...")
      download_list.each_with_index do |mid, i|
        mod_json = GitHub.fetch_mod_json(mid)
        mod_name = mod_json ? mod_json["name"].to_s : mid
        overlay.update(mod_name, i, nil, 0, 0)

        if overlay.cancelled?
          _handle_cancel(overlay)
          return
        end

        if GitHub.download_mod(mid)
          ModManager.refresh
          GitHub.mark_installed(mid)
          overlay.add_to_batch(mid)
        end
      end
      overlay.update("Done!", download_list.length)
      overlay.dispose

      show_message("#{download_list.length} mod(s) installed!\nRestart the game to apply.")
      @import_decoded = nil
      draw_left
      draw_right
    end

    def _text_input(prompt, max_len)
      text = ""
      dim = Sprite.new(@vp)
      dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(0, 0, 0, 120))
      dim.z = 900

      box_w = 360
      box_h = 70
      box = Sprite.new(@vp)
      box.bitmap = Bitmap.new(box_w, box_h)
      box.x = (SCREEN_W - box_w) / 2
      box.y = (SCREEN_H - box_h) / 2
      box.z = 901

      cursor_frame = 0
      loop do
        b = box.bitmap
        b.clear
        draw_rounded_rect(b, 0, 0, box_w, box_h, Color.new(40, 35, 60))
        draw_border(b, 0, 0, box_w, box_h, Color.new(120, 100, 180))
        pbSetSmallFont(b)
        pbDrawShadowText(b, 12, 8, box_w - 24, 16, prompt, WHITE, SHADOW)

        cursor = (cursor_frame / 20) % 2 == 0 ? "|" : ""
        draw_rounded_rect(b, 12, 30, box_w - 24, 22, SEARCH_BG)
        pbDrawShadowText(b, 16, 30, box_w - 32, 22, text + cursor, WHITE, SHADOW)
        pbDrawShadowText(b, 0, box_h - 18, box_w, 14, "Enter: Confirm  |  ESC: Cancel", DIM, SHADOW, 2)

        Graphics.update
        Input.update
        cursor_frame += 1

        # ESC
        if Input.trigger?(Input::B)
          text = nil
          break
        end
        # Enter
        if _key_trigger?(0x0D)
          break
        end
        # Backspace
        if _key_repeat?(0x08)
          text = text[0...-1] unless text.empty?
        end
        # Ctrl+V paste
        if _key_pressed?(0x11) && _key_trigger?(0x56)
          pasted = ModManager.clipboard_read
          if pasted && pasted.is_a?(String)
            text = pasted.strip[0, max_len]
          end
        end

        (0x41..0x5A).each do |vk|
          if _key_trigger?(vk)
            ch = (vk - 0x41 + 97).chr
            ch = ch.upcase if _key_pressed?(0x10)
            text += ch if text.length < max_len
          end
        end
        (0x30..0x39).each do |vk|
          text += (vk - 0x30).to_s if _key_trigger?(vk) && text.length < max_len
        end
        if _key_trigger?(0xBD)
          text += (_key_pressed?(0x10) ? "_" : "-") if text.length < max_len
        end
      end

      box.bitmap.dispose
      box.dispose
      dim.bitmap.dispose
      dim.dispose
      text
    end

    #==========================================================================
    # Cancel + rollback handler for progress overlay
    #==========================================================================
    def _handle_cancel(overlay)
      batch = overlay.batch_installed.dup
      overlay.dispose

      if batch.empty?
        show_message("Download cancelled.\nNo mods were installed.")
        return
      end

      result = show_message(
        "Download cancelled.\n#{batch.length} mod(s) already downloaded.\n\nKeep them?",
        ["Keep installed", "Undo (delete all)"]
      )
      if result == 1
        batch.each { |mid| ModManager.uninstall(mid) }
        ModManager.refresh
        show_message("Rolled back #{batch.length} mod(s).")
      end
      draw_left
      draw_right
    end

    # Helpers for special (pinned) entries
    def _special_installed?(folder)
      case folder
      when "_kif_multiplayer" then GitHub.mp_installed?
      when "_aleks_npt" then GitHub.npt_installed?
      else false
      end
    end

    def _special_local_version(folder)
      case folder
      when "_kif_multiplayer" then GitHub.mp_local_version
      when "_aleks_npt" then GitHub.npt_local_version
      else nil
      end
    end

    #==========================================================================
    # Helpers
    #==========================================================================
    def _get_description(json)
      return "" unless json
      desc = json["description"]
      return desc.join("\n") if desc.is_a?(Array)
      return desc.to_s
    end

    def apply_filter
      list = @remote_mods
      unless @search_text.empty?
        q = @search_text.downcase
        list = list.select do |entry|
          folder = entry["folder"].downcase
          json = entry["json"]
          name = json ? json["name"].to_s.downcase : ""
          desc = json ? _get_description(json).downcase : ""
          folder.include?(q) || name.include?(q) || desc.include?(q)
        end
      end
      if @filter_tag
        tag_q = @filter_tag.downcase
        list = list.select do |entry|
          json = entry["json"]
          next false unless json && json["tags"].is_a?(Array)
          json["tags"].any? { |t| t.to_s.downcase == tag_q }
        end
      end
      @filtered_mods = list
      @sel_index = @sel_index.clamp(0, [(@filtered_mods.length - 1), 0].max)
      ensure_visible
    end

    # Modpack-specific filter methods
    def apply_filter_modpacks
      list = @remote_modpacks
      unless @search_text.empty?
        q = @search_text.downcase
        list = list.select do |entry|
          folder = entry["folder"].downcase
          json = entry["json"]
          name = json ? json["name"].to_s.downcase : ""
          desc = json ? _get_description(json).downcase : ""
          folder.include?(q) || name.include?(q) || desc.include?(q)
        end
      end
      if @filter_tag
        tag_q = @filter_tag.downcase
        list = list.select do |entry|
          json = entry["json"]
          next false unless json && json["tags"].is_a?(Array)
          json["tags"].any? { |t| t.to_s.downcase == tag_q }
        end
      end
      @filtered_modpacks = list
      @sel_index = @sel_index.clamp(0, [(@filtered_modpacks.length - 1), 0].max)
      ensure_visible_modpacks
    end

    def ensure_visible_modpacks
      rpp = rows_per_page
      return if @filtered_modpacks.empty?
      @scroll = @sel_index if @sel_index < @scroll
      @scroll = @sel_index - rpp + 1 if @sel_index >= @scroll + rpp
      max_scroll = [@filtered_modpacks.length - rpp, 0].max
      @scroll = @scroll.clamp(0, max_scroll)
    end

    def cycle_tag_filter_modpacks
      tags = ModManager::VALID_TAGS rescue []
      choices = ["All (no filter)"] + tags
      result = show_message("Filter by tag:", choices)
      @filter_tag = result == 0 ? nil : tags[result - 1]
      @sel_index = 0
      @scroll = 0
      apply_filter_modpacks
      draw_title
      draw_footer
      draw_left
      draw_right
    end

    def cycle_tag_filter
      tags = ModManager::VALID_TAGS rescue [
        "Gameplay", "Visual", "Audio", "QoL", "Balance", "Difficulty",
        "Fusion", "Multiplayer", "UI", "Cosmetic", "Bug Fix", "Content"
      ]
      # Show tag picker
      choices = ["All (no filter)"] + tags
      result = show_message("Filter by tag:", choices)
      @filter_tag = result == 0 ? nil : tags[result - 1]
      @sel_index = 0
      @scroll = 0
      @last_drawn_sel = -1
      apply_filter
      draw_title
      draw_footer
      draw_left
      draw_right
    end

    def rows_per_page
      (LIST_H / ROW_H).floor
    end

    def ensure_visible
      rpp = rows_per_page
      return if @filtered_mods.empty?
      @scroll = @sel_index if @sel_index < @scroll
      @scroll = @sel_index - rpp + 1 if @sel_index >= @scroll + rpp
      max_scroll = [@filtered_mods.length - rpp, 0].max
      @scroll = @scroll.clamp(0, max_scroll)
    end

    # ── Custom in-viewport message box ──────────────────────────────────
    def show_message(text, choices = nil)
      # Consume lingering key states
      _init_gas
      if @_gas
        [0x0D, 0x5A, 0x20].each { |vk| @_gas.call(vk) }
      end
      Graphics.update
      Input.update

      # Darken overlay
      dim = Sprite.new(@vp)
      dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(0, 0, 0, 120))
      dim.z = 900

      # Message box
      box_w = 320
      lines = text.split("\n")
      choice_count = choices ? choices.length : 0
      line_h = 18
      padding = 16
      box_h = padding * 2 + lines.length * line_h + (choice_count > 0 ? choice_count * line_h + 8 : line_h)
      box_x = (SCREEN_W - box_w) / 2
      box_y = (SCREEN_H - box_h) / 2

      box = Sprite.new(@vp)
      box.bitmap = Bitmap.new(box_w, box_h)
      box.x = box_x
      box.y = box_y
      box.z = 901

      b = box.bitmap
      draw_rounded_rect(b, 0, 0, box_w, box_h, Color.new(40, 35, 60))
      draw_border(b, 0, 0, box_w, box_h, Color.new(120, 100, 180))

      pbSetSmallFont(b)
      ty = padding
      lines.each do |line|
        pbDrawShadowText(b, padding, ty, box_w - padding * 2, line_h, line, WHITE, SHADOW)
        ty += line_h
      end

      selected = 0
      if choices
        ty += 4
        _draw_choices(b, choices, selected, padding, ty, box_w, line_h)
      else
        ty += 4
        pbDrawShadowText(b, 0, ty, box_w, line_h, "[OK]", GRAY, SHADOW, 2)
      end

      loop do
        Graphics.update
        Input.update

        if choices
          old_sel = selected
          if Input.trigger?(Input::UP)
            selected = (selected - 1) % choices.length
          elsif Input.trigger?(Input::DOWN)
            selected = (selected + 1) % choices.length
          end

          mx = Input.mouse_x rescue nil
          my = Input.mouse_y rescue nil
          if mx && my
            choice_base_y = box_y + padding + lines.length * line_h + 4
            if mx >= box_x + padding && mx < box_x + box_w - padding
              choices.each_with_index do |_, ci|
                cy = choice_base_y + ci * line_h
                if my >= cy && my < cy + line_h
                  selected = ci
                  break
                end
              end
            end
          end

          if selected != old_sel
            _draw_choices(b, choices, selected, padding,
                          padding + lines.length * line_h + 4, box_w, line_h)
          end

          if Input.trigger?(Input::C) || (Input.trigger?(Input::MOUSELEFT) rescue false)
            break
          end
        else
          if Input.trigger?(Input::C) || Input.trigger?(Input::B) ||
             (Input.trigger?(Input::MOUSELEFT) rescue false)
            break
          end
        end

        if choices && (Input.trigger?(Input::B) || (Input.trigger?(Input::MOUSERIGHT) rescue false))
          selected = choices.length - 1
          break
        end
      end

      box.bitmap.dispose
      box.dispose
      dim.bitmap.dispose
      dim.dispose

      selected
    end

    def _draw_choices(bmp, choices, selected, px, ty, box_w, line_h)
      bmp.fill_rect(px, ty - 2, box_w - px * 2, choices.length * line_h + 4, Color.new(40, 35, 60))
      choices.each_with_index do |label, i|
        if i == selected
          bmp.fill_rect(px, ty + i * line_h, box_w - px * 2, line_h, Color.new(80, 60, 130))
          pbDrawShadowText(bmp, px + 8, ty + i * line_h, box_w - px * 2, line_h, "> #{label}", WHITE, SHADOW)
        else
          pbDrawShadowText(bmp, px + 8, ty + i * line_h, box_w - px * 2, line_h, label, GRAY, SHADOW)
        end
      end
    end

    # Status overlay (non-interactive, for "Downloading...")
    def show_status(text)
      hide_status
      @status_dim = Sprite.new(@vp)
      @status_dim.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      @status_dim.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H, Color.new(0, 0, 0, 120))
      @status_dim.z = 900

      box_w = 280
      box_h = 48
      @status_box = Sprite.new(@vp)
      @status_box.bitmap = Bitmap.new(box_w, box_h)
      @status_box.x = (SCREEN_W - box_w) / 2
      @status_box.y = (SCREEN_H - box_h) / 2
      @status_box.z = 901
      draw_rounded_rect(@status_box.bitmap, 0, 0, box_w, box_h, Color.new(40, 35, 60))
      draw_border(@status_box.bitmap, 0, 0, box_w, box_h, Color.new(120, 100, 180))
      pbSetSmallFont(@status_box.bitmap)
      pbDrawShadowText(@status_box.bitmap, 0, 14, box_w, 20, text, WHITE, SHADOW, 2)
      Graphics.update
    end

    def hide_status
      if @status_box
        @status_box.bitmap.dispose rescue nil
        @status_box.dispose rescue nil
        @status_box = nil
      end
      if @status_dim
        @status_dim.bitmap.dispose rescue nil
        @status_dim.dispose rescue nil
        @status_dim = nil
      end
    end

    def _init_gas
      @_gas ||= begin
        Win32API.new('user32', 'GetAsyncKeyState', ['i'], 'i')
      rescue
        nil
      end
    end

    def _init_focus_api
      return if @_focus_api_init
      @_focus_api_init = true
      begin
        @_gfw = Win32API.new('user32', 'GetForegroundWindow', [], 'i')
        @_gwtpi = Win32API.new('user32', 'GetWindowThreadProcessId', ['i', 'p'], 'i')
      rescue
        @_gfw = nil
        @_gwtpi = nil
      end
    end

    def _window_active?
      _init_focus_api
      return true unless @_gfw && @_gwtpi
      begin
        foreground = @_gfw.call
        return true if foreground == 0
        pid_buf = [0].pack('L')
        @_gwtpi.call(foreground, pid_buf)
        foreground_pid = pid_buf.unpack('L')[0]
        return foreground_pid == Process.pid
      rescue
        true
      end
    end

    def _key_trigger?(vk_code)
      _init_gas
      return false unless @_gas
      return false unless _window_active?
      (@_gas.call(vk_code) & 0x01) != 0
    rescue
      false
    end

    def _key_pressed?(vk_code)
      _init_gas
      return false unless @_gas
      return false unless _window_active?
      (@_gas.call(vk_code) & 0x8000) != 0
    rescue
      false
    end

    def _key_repeat?(vk_code)
      @_repeat_timers ||= {}
      if _key_pressed?(vk_code)
        @_repeat_timers[vk_code] ||= 0
        @_repeat_timers[vk_code] += 1
        t = @_repeat_timers[vk_code]
        return t == 1 || (t > 12 && t % 4 == 0)
      else
        @_repeat_timers[vk_code] = 0
        return false
      end
    end

    def draw_rounded_rect(bmp, x, y, w, h, color)
      bmp.fill_rect(x + 2, y, w - 4, h, color)
      bmp.fill_rect(x, y + 2, w, h - 4, color)
      bmp.fill_rect(x + 1, y + 1, w - 2, h - 2, color)
    end

    def draw_border(bmp, x, y, w, h, color)
      bmp.fill_rect(x + 2, y, w - 4, 1, color)
      bmp.fill_rect(x + 2, y + h - 1, w - 4, 1, color)
      bmp.fill_rect(x, y + 2, 1, h - 4, color)
      bmp.fill_rect(x + w - 1, y + 2, 1, h - 4, color)
    end

    # Launch a .bat file in a new CMD window, avoiding shell escaping issues
    # by writing a temporary launcher script.
    def _launch_bat(title, script_path, args)
      temp = ENV['TEMP'] || ENV['TMP'] || '.'
      launcher = File.join(temp, "_kif_launcher.bat")
      win_script = script_path.gsub('/', '\\')
      quoted_args = args.map { |a|
        val = a.include?("://") ? a : a.gsub('/', '\\')
        "\"#{val}\""
      }.join(' ')
      File.open(launcher, 'w') do |f|
        f.puts "@echo off"
        f.puts "title #{title}"
        f.puts "call \"#{win_script}\" #{quoted_args}"
        f.puts "pause"
        f.puts "del \"%~f0\" >NUL 2>&1"
      end
      win_launcher = launcher.gsub('/', '\\')
      Process.spawn("cmd /c \"#{win_launcher}\"")
    end
  end
end
