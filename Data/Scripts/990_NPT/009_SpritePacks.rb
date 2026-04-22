#==============================================================================
# 990_NPT — New Pokémon Tool
# File: 009_SpritePacks.rb
# Purpose: Lazy extraction of sprites from per-head .pak bundles.
#
# PACK FORMAT (SPAK v2)
# ─────────────────────
#   [4]     magic: "SPAK"
#   [4]     N: uint32  (sprite count)
#   [N*16]  index: [body_id u32][alt_index u32][offset u32][length u32]
#             body_id    0 = unfused battler ({head}.png)
#             alt_index  0 = main (""), 1 = 'a', 2 = 'b', ... 26 = 'z'
#   [...]   raw PNG bytes concatenated
#
# HOW IT INTEGRATES
# ─────────────────
# Aliases download_autogen_sprite and download_custom_sprite (HttpCalls.rb).
# Those are called exactly when a local file is missing, before any HTTP
# request.  On first call for a given head, ALL sprites in that head's pack
# are extracted to the normal game folder at once.  This ensures pbResolveBitmap
# (used by pbGetAvailableAlts / Pokédex gallery) finds all alt sprites via the
# regular filesystem scan immediately after the first extraction.
#
# After any head is extracted once, all its files are plain PNGs on disk —
# no further pack involvement.
#==============================================================================

module SpritePacks
  BATTLERS_PACK_DIR = "Graphics/Battlers_packed/"
  CUSTOM_PACK_DIR   = "Graphics/CustomBattlers_packed/"

  MAGIC          = "SPAK"
  INDEX_ENTRY_SZ = 16   # 4×uint32

  # Tracks which (pack_dir, head_id) pairs have already been fully extracted.
  @extracted_heads = {}

  def self.alt_index_to_str(a_idx)
    return "" if a_idx == 0
    (a_idx - 1 + 'a'.ord).chr
  end

  # Extract ALL sprites for a given head from its pack into dst_dir.
  # Skips files that already exist on disk.
  # Returns true if the pack was found and processed (even if all files existed),
  # false if no pack was found.
  def self.extract_head(head_id, pack_dir, dst_dir)
    key = "#{pack_dir}:#{head_id}"
    return @extracted_heads[key] if @extracted_heads.key?(key)

    pack_path = pack_dir + head_id.to_s + ".pak"
    unless FileTest.exist?(pack_path)
      @extracted_heads[key] = false
      return false
    end

    begin
      File.open(pack_path, "rb") do |f|
        unless f.read(4) == MAGIC
          @extracted_heads[key] = false
          return false
        end

        count      = f.read(4).unpack1("V")
        data_start = 8 + count * INDEX_ENTRY_SZ

        # Read full index first
        index = Array.new(count) { f.read(INDEX_ENTRY_SZ).unpack("VVVV") }

        dst_folder = dst_dir + head_id.to_s
        Dir.mkdir(dst_folder) unless FileTest.exist?(dst_folder)

        index.each do |b_id, a_idx, off, len|
          alt_str  = alt_index_to_str(a_idx)
          filename = b_id == 0 ? "#{head_id}#{alt_str}.png"
                                : "#{head_id}.#{b_id}#{alt_str}.png"
          dst_path = dst_folder + "/" + filename
          next if FileTest.exist?(dst_path)

          f.seek(data_start + off)
          File.open(dst_path, "wb") { |out| out.write(f.read(len)) }
        end
      end
    rescue => e
      echoln "[SpritePacks] Warning: extraction failed for head #{head_id} in #{pack_dir}: #{e}"
      @extracted_heads[key] = false
      return false
    end

    @extracted_heads[key] = true
    true
  end

  # Return the expected on-disk path for one sprite (does not extract).
  def self.sprite_path(head_id, body_id, alt_letter, dst_dir)
    alt_str  = alt_letter.to_s
    filename = body_id == 0 ? "#{head_id}#{alt_str}.png"
                             : "#{head_id}.#{body_id}#{alt_str}.png"
    dst_dir + head_id.to_s + "/" + filename
  end
end

# ── Intercept download_autogen_sprite (Graphics/Battlers/) ────────────────────
alias _spak_orig_download_autogen download_autogen_sprite
def download_autogen_sprite(head_id, body_id, spriteformBody_suffix = nil, spriteformHead_suffix = nil)
  unless spriteformBody_suffix || spriteformHead_suffix
    if SpritePacks.extract_head(head_id.to_i, SpritePacks::BATTLERS_PACK_DIR, Settings::BATTLERS_FOLDER)
      path = SpritePacks.sprite_path(head_id.to_i, body_id.to_i, "", Settings::BATTLERS_FOLDER)
      return path if FileTest.exist?(path)
    end
  end
  _spak_orig_download_autogen(head_id, body_id, spriteformBody_suffix, spriteformHead_suffix)
end

# ── Intercept download_custom_sprite (Graphics/CustomBattlers/indexed/) ───────
alias _spak_orig_download_custom download_custom_sprite
def download_custom_sprite(head_id, body_id, spriteformBody_suffix = "", spriteformHead_suffix = "", alt_letter = "")
  if spriteformBody_suffix.to_s.empty? && spriteformHead_suffix.to_s.empty?
    if SpritePacks.extract_head(head_id.to_i, SpritePacks::CUSTOM_PACK_DIR, Settings::CUSTOM_BATTLERS_FOLDER_INDEXED)
      path = SpritePacks.sprite_path(head_id.to_i, body_id.to_i, alt_letter.to_s, Settings::CUSTOM_BATTLERS_FOLDER_INDEXED)
      return path if FileTest.exist?(path)
    end
  end
  _spak_orig_download_custom(head_id, body_id, spriteformBody_suffix, spriteformHead_suffix, alt_letter)
end

echoln "[990_NPT] SpritePacks loaded — pack dirs: #{SpritePacks::BATTLERS_PACK_DIR}, #{SpritePacks::CUSTOM_PACK_DIR}"
