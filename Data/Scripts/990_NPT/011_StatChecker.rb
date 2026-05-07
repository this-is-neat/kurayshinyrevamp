#===============================================================================
# NPT Stat Checker — Fusion & Form Base Stat Viewer
# File: 990_NPT/011_StatChecker.rb
#
# Adds a "Stat Checker" option to the party menu that opens a read-only
# overlay showing 6 base stats + BST. For fusions, cycle through all
# head form × body form combinations. For non-fusions, cycle through
# all registered forms (base, mega, alternate, etc.).
#===============================================================================

module NPTStatChecker

  # ── Fusion stat formula (mirrors FusedSpecies#calculate_fused_stats) ──────
  def self.fused_stat(dominant, other)
    ((2 * dominant) / 3) + (other / 3).floor
  end

  # Compute full fused base stats from two species data objects
  def self.compute_fusion_stats(head_data, body_data)
    hs = head_data.base_stats
    bs = body_data.base_stats
    {
      HP:              fused_stat(hs[:HP],              bs[:HP]),
      ATTACK:          fused_stat(bs[:ATTACK],          hs[:ATTACK]),
      DEFENSE:         fused_stat(bs[:DEFENSE],         hs[:DEFENSE]),
      SPECIAL_ATTACK:  fused_stat(hs[:SPECIAL_ATTACK],  bs[:SPECIAL_ATTACK]),
      SPECIAL_DEFENSE: fused_stat(hs[:SPECIAL_DEFENSE], bs[:SPECIAL_DEFENSE]),
      SPEED:           fused_stat(bs[:SPEED],           hs[:SPEED])
    }
  end

  # ── Form enumeration ─────────────────────────────────────────────────────
  # Returns all registered species data entries for a given base species symbol.
  # e.g. for :PALAFIN returns [:PALAFIN (form 0), :PALAFIN_1 (form 1)]
  def self.get_all_forms(base_species)
    forms = []
    GameData::Species::DATA.each do |key, sp_data|
      next if key.is_a?(Integer)
      forms << sp_data if sp_data.species == base_species
    end
    forms.sort_by { |f| f.form }
  end

  # ── Build combo list for a Pokemon ──────────────────────────────────────
  # Returns an array of hashes: { label:, stats:, bst: }
  def self.build_combos(pkmn)
    dex_num = pkmn.species_data.id_number rescue 0
    is_fusion = dex_num > Settings::NB_POKEMON rescue false

    if is_fusion && pkmn.species_data.is_a?(GameData::FusedSpecies)
      build_fusion_combos(pkmn)
    else
      build_form_combos(pkmn)
    end
  end

  # ── Fusion combos: head forms × body forms ──────────────────────────────
  def self.build_fusion_combos(pkmn)
    sd = pkmn.species_data
    head_base = sd.head_pokemon.species rescue sd.head_pokemon.id
    body_base = sd.body_pokemon.species rescue sd.body_pokemon.id

    head_forms = get_all_forms(head_base)
    body_forms = get_all_forms(body_base)

    # Fallback if enumeration fails
    head_forms = [sd.head_pokemon] if head_forms.empty?
    body_forms = [sd.body_pokemon] if body_forms.empty?

    combos = []
    head_forms.each do |hf|
      body_forms.each do |bf|
        stats = compute_fusion_stats(hf, bf)
        bst = stats.values.sum

        h_label = form_label(hf)
        b_label = form_label(bf)
        label = "#{h_label} / #{b_label}"

        combos << { label: label, stats: stats, bst: bst,
                    head_data: hf, body_data: bf }
      end
    end
    combos
  end

  # ── Non-fusion combos: iterate all forms ────────────────────────────────
  def self.build_form_combos(pkmn)
    base_species = pkmn.species_data.species rescue pkmn.species
    forms = get_all_forms(base_species)
    forms = [pkmn.species_data] if forms.empty?

    combos = []
    forms.each do |f|
      stats = {}
      bs = f.base_stats
      GameData::Stat.each_main { |s| stats[s.id] = bs[s.id] }
      bst = stats.values.sum
      combos << { label: form_label(f), stats: stats, bst: bst }
    end
    combos
  end

  # Human-readable form label
  def self.form_label(sp_data)
    name = sp_data.real_name rescue sp_data.name rescue sp_data.id.to_s
    form_name = sp_data.real_form_name rescue nil
    if form_name && form_name != "" && form_name != nil
      "#{name} (#{form_name})"
    else
      name
    end
  end

  #=========================================================================
  # Overlay Scene
  #=========================================================================
  class Scene
    # Color constants
    WHITE    = Color.new(255, 255, 255)
    SHADOW   = Color.new(80, 80, 80)
    BLACK    = Color.new(0, 0, 0)
    DARK_BG  = Color.new(30, 30, 40, 220)
    BAR_BG   = Color.new(60, 60, 75)
    STAT_COLORS = {
      HP:              Color.new(255, 100, 100),
      ATTACK:          Color.new(240, 160, 60),
      DEFENSE:         Color.new(240, 220, 80),
      SPECIAL_ATTACK:  Color.new(100, 160, 255),
      SPECIAL_DEFENSE: Color.new(100, 220, 140),
      SPEED:           Color.new(240, 120, 200)
    }
    STAT_NAMES = {
      HP: "HP", ATTACK: "Atk", DEFENSE: "Def",
      SPECIAL_ATTACK: "SpAtk", SPECIAL_DEFENSE: "SpDef", SPEED: "Speed"
    }
    STAT_ORDER = [:HP, :ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED]

    def initialize(pkmn)
      @pkmn = pkmn
      @combos = NPTStatChecker.build_combos(pkmn)
      @index = find_current_index
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 100000
      @sprites = {}
      @sprites["bg"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["overlay"].z = 1
      pbSetSystemFont(@sprites["overlay"].bitmap)
      draw
    end

    # Try to find the combo matching the Pokemon's current form
    def find_current_index
      return 0 if @combos.length <= 1
      sd = @pkmn.species_data

      if sd.is_a?(GameData::FusedSpecies)
        head_id = sd.head_pokemon.id rescue nil
        body_id = sd.body_pokemon.id rescue nil
        @combos.each_with_index do |c, i|
          if c[:head_data] && c[:body_data]
            return i if c[:head_data].id == head_id && c[:body_data].id == body_id
          end
        end
      else
        current_id = sd.id rescue @pkmn.species
        @combos.each_with_index do |c, i|
          return i if c[:label] == NPTStatChecker.form_label(sd)
        end
      end
      0
    end

    def draw
      bg = @sprites["bg"].bitmap
      bg.clear
      # Darken background
      bg.fill_rect(0, 0, Graphics.width, Graphics.height, DARK_BG)

      # Main panel
      panel_x = 16
      panel_y = 16
      panel_w = Graphics.width - 32
      panel_h = Graphics.height - 32
      draw_rounded_rect(bg, panel_x, panel_y, panel_w, panel_h,
                        Color.new(45, 45, 60, 240))
      # Border
      draw_border(bg, panel_x, panel_y, panel_w, panel_h,
                  Color.new(120, 120, 160))

      overlay = @sprites["overlay"].bitmap
      overlay.clear
      pbSetSystemFont(overlay)

      combo = @combos[@index]

      # ── Header ──────────────────────────────────────────────────────────
      title = @pkmn.name
      draw_text(overlay, panel_x + 18, panel_y + 10, title, WHITE, SHADOW, :left)

      # Close hint (right side of header)
      draw_text_small(overlay, panel_x + panel_w - 18, panel_y + 12,
                      "X / ESC to close",
                      Color.new(140, 140, 160), SHADOW, :right)

      # Form label
      form_text = combo[:label]
      draw_text_small(overlay, Graphics.width / 2, panel_y + 34, form_text,
                      Color.new(200, 200, 255), SHADOW, :center)

      # Navigation hint
      nav = "< LEFT / RIGHT >   (#{@index + 1}/#{@combos.length})"
      draw_text_small(overlay, Graphics.width / 2, panel_y + 52, nav,
                      Color.new(160, 160, 180), SHADOW, :center)

      # ── Stat bars ───────────────────────────────────────────────────────
      bar_x = panel_x + 90
      bar_y_start = panel_y + 78
      bar_w = panel_w - 150
      bar_h = 18
      spacing = 36

      max_stat = [combo[:stats].values.max, 180].max  # Scale bars relative to max

      STAT_ORDER.each_with_index do |stat, i|
        y = bar_y_start + (i * spacing)
        val = combo[:stats][stat] || 0
        name = STAT_NAMES[stat]
        color = STAT_COLORS[stat]

        # Stat name
        draw_text_small(overlay, panel_x + 18, y, name, WHITE, SHADOW, :left)

        # Bar background
        bg.fill_rect(bar_x, y + 2, bar_w, bar_h, BAR_BG)

        # Filled bar
        fill_w = [(val.to_f / max_stat * bar_w).to_i, bar_w].min
        fill_w = [fill_w, 2].max
        bg.fill_rect(bar_x, y + 2, fill_w, bar_h, color)

        # Stat value
        draw_text_small(overlay, bar_x + bar_w + 8, y, val.to_s, WHITE, SHADOW, :left)
      end

      # ── BST ─────────────────────────────────────────────────────────────
      bst_y = bar_y_start + (6 * spacing) + 4
      draw_text(overlay, panel_x + 18, bst_y, "BST", WHITE, SHADOW, :left)
      draw_text(overlay, bar_x + bar_w + 8, bst_y, combo[:bst].to_s,
                Color.new(255, 220, 100), SHADOW, :left)

    end

    def main_loop
      loop do
        Graphics.update
        Input.update
        if Input.trigger?(Input::B)
          break
        elsif Input.trigger?(Input::LEFT) || Input.repeat?(Input::LEFT)
          @index = (@index - 1) % @combos.length
          draw
        elsif Input.trigger?(Input::RIGHT) || Input.repeat?(Input::RIGHT)
          @index = (@index + 1) % @combos.length
          draw
        end
      end
    end

    def dispose
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end

    # ── Drawing helpers ───────────────────────────────────────────────────
    private

    def draw_text(bmp, x, y, text, color, shadow_color, align = :left)
      px = x
      px = x - bmp.text_size(text).width / 2 if align == :center
      px = x - bmp.text_size(text).width if align == :right
      pbDrawTextPositions(bmp, [[text, px + 1, y + 1, 0, shadow_color, nil]])
      pbDrawTextPositions(bmp, [[text, px, y, 0, color, nil]])
    end

    def draw_text_small(bmp, x, y, text, color, shadow_color, align = :left)
      pbSetSmallFont(bmp)
      draw_text(bmp, x, y, text, color, shadow_color, align)
      pbSetSystemFont(bmp)
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
  end

  #=========================================================================
  # Public API
  #=========================================================================
  def self.open(pkmn)
    return if pkmn.egg?
    scene = Scene.new(pkmn)
    scene.main_loop
    scene.dispose
  end
end

#===============================================================================
# Hook into Party Menu — inject "Stat Checker" command via alias chain
# (avoids editing core 016_UI/005_UI_Party.rb)
#===============================================================================
class PokemonPartyScreen
  alias _npt_stat_checker_pokemon_screen pbPokemonScreen unless method_defined?(:_npt_stat_checker_pokemon_screen)

  def pbPokemonScreen
    @scene.pbStartScene(@party,
                        (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."), nil)
    loop do
      @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
      pkmnid = @scene.pbChoosePokemon(false, -1, 1)
      break if (pkmnid.is_a?(Numeric) && pkmnid < 0) || (pkmnid.is_a?(Array) && pkmnid[1] < 0)
      if pkmnid.is_a?(Array) && pkmnid[0] == 1 # Switch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid[1]
        pkmnid = @scene.pbChoosePokemon(true, -1, 2)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
        next
      end
      pkmn = @party[pkmnid]
      commands = []
      cmdSummary = -1
      cmdStatChecker = -1
      cmdNickname = -1
      cmdDebug = -1
      cmdMoves = [-1] * pkmn.numMoves
      cmdSwitch = -1
      cmdMail = -1
      cmdItem = -1
      cmdHat = -1

      # Build the commands — Stat Checker inserted right after Summary
      commands[cmdSummary = commands.length] = _INTL("Summary")
      commands[cmdStatChecker = commands.length] = _INTL("Stat Checker") if !pkmn.egg?
      commands[cmdDebug = commands.length] = _INTL("Debug") if $DEBUG
      if !pkmn.egg?
        pkmn.moves.each_with_index do |m, i|
          if [:MILKDRINK, :SOFTBOILED].include?(m.id) ||
            HiddenMoveHandlers.hasHandler(m.id)
            commands[cmdMoves[i] = commands.length] = [m.name, 1]
          end
        end
      end
      commands[cmdSwitch = commands.length] = _INTL("Switch") if @party.length > 1
      commands[cmdHat = commands.length] = _INTL("Hat") if canPutHatOnPokemon(pkmn)
      if !pkmn.egg?
        if pkmn.mail
          commands[cmdMail = commands.length] = _INTL("Mail")
        else
          commands[cmdItem = commands.length] = _INTL("Item")
        end
      end
      commands[cmdNickname = commands.length] = _INTL("Nickname") if !pkmn.egg?
      commands[commands.length] = _INTL("Cancel")
      command = @scene.pbShowCommands(_INTL("Do what with {1}?", pkmn.name), commands)
      havecommand = false
      cmdMoves.each_with_index do |cmd, i|
        next if cmd < 0 || cmd != command
        havecommand = true
        if [:MILKDRINK, :SOFTBOILED].include?(pkmn.moves[i].id)
          amt = [(pkmn.totalhp / 5).floor, 1].max
          if pkmn.hp <= amt
            pbDisplay(_INTL("Not enough HP..."))
            break
          end
          @scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          oldpkmnid = pkmnid
          loop do
            @scene.pbPreSelect(oldpkmnid)
            pkmnid = @scene.pbChoosePokemon(true, pkmnid)
            break if pkmnid < 0
            newpkmn = @party[pkmnid]
            movename = pkmn.moves[i].name
            if pkmnid == oldpkmnid
              pbDisplay(_INTL("{1} can't use {2} on itself!", pkmn.name, movename))
            elsif newpkmn.egg?
              pbDisplay(_INTL("{1} can't be used on an Egg!", movename))
            elsif newpkmn.hp == 0 || newpkmn.hp == newpkmn.totalhp
              pbDisplay(_INTL("{1} can't be used on that Pokémon.", movename))
            else
              pkmn.hp -= amt
              hpgain = pbItemRestoreHP(newpkmn, amt)
              @scene.pbDisplay(_INTL("{1}'s HP was restored by {2} points.", newpkmn.name, hpgain))
              pbRefresh
            end
            break if pkmn.hp <= amt
          end
          @scene.pbSelect(oldpkmnid)
          pbRefresh
          break
        elsif pbCanUseHiddenMove?(pkmn, pkmn.moves[i].id)
          if pbConfirmUseHiddenMove(pkmn, pkmn.moves[i].id)
            @scene.pbEndScene
            if pkmn.moves[i].id == :FLY || pkmn.moves[i].id == :TELEPORT
              ret = pbBetterRegionMap(-1, true, true)
              if ret
                $PokemonTemp.flydata = ret
                return [pkmn, pkmn.moves[i].id]
              end
              @scene.pbStartScene(@party,
                                  (@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
              break
            end
            return [pkmn, pkmn.moves[i].id]
          end
        end
      end
      next if havecommand
      if cmdSummary >= 0 && command == cmdSummary
        @scene.pbSummary(pkmnid) {
          @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
        }
      elsif cmdStatChecker >= 0 && command == cmdStatChecker
        NPTStatChecker.open(pkmn)
      elsif cmdHat >= 0 && command == cmdHat
        pbPokemonHat(pkmn)
      elsif cmdNickname >= 0 && command == cmdNickname
        pbPokemonRename(pkmn,pkmnid)
      elsif cmdDebug >= 0 && command == cmdDebug
        pbPokemonDebug(pkmn, pkmnid)
      elsif cmdSwitch >= 0 && command == cmdSwitch
        @scene.pbSetHelpText(_INTL("Move to where?"))
        oldpkmnid = pkmnid
        pkmnid = @scene.pbChoosePokemon(true)
        if pkmnid >= 0 && pkmnid != oldpkmnid
          pbSwitch(oldpkmnid, pkmnid)
        end
      elsif cmdMail >= 0 && command == cmdMail
        command = @scene.pbShowCommands(_INTL("Do what with the mail?"),
                                        [_INTL("Read"), _INTL("Take"), _INTL("Cancel")])
        case command
        when 0 # Read
          pbFadeOutIn {
            pbDisplayMail(pkmn.mail, pkmn)
            @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
        when 1 # Take
          if pbTakeItemFromPokemon(pkmn, self)
            pbRefreshSingle(pkmnid)
          end
        end
      elsif cmdItem >= 0 && command == cmdItem
        itemcommands = []
        cmdUseItem = -1
        cmdGiveItem = -1
        cmdTakeItem = -1
        cmdMoveItem = -1
        itemcommands[cmdUseItem = itemcommands.length] = _INTL("Use")
        itemcommands[cmdGiveItem = itemcommands.length] = _INTL("Give")
        itemcommands[cmdTakeItem = itemcommands.length] = _INTL("Take") if pkmn.hasItem?
        itemcommands[cmdMoveItem = itemcommands.length] = _INTL("Move") if pkmn.hasItem? &&
          !GameData::Item.get(pkmn.item).is_mail?
        itemcommands[itemcommands.length] = _INTL("Cancel")
        command = @scene.pbShowCommands(_INTL("Do what with an item?"), itemcommands)
        if cmdUseItem >= 0 && command == cmdUseItem # Use
          item = @scene.pbUseItem($PokemonBag, pkmn) {
            @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
          if item
            pbUseItemOnPokemon(item, pkmn, self)
            pbRefreshSingle(pkmnid)
          end
        elsif cmdGiveItem >= 0 && command == cmdGiveItem # Give
          item = @scene.pbChooseItem($PokemonBag) {
            @scene.pbSetHelpText((@party.length > 1) ? _INTL("Choose a Pokémon.") : _INTL("Choose Pokémon or cancel."))
          }
          if item
            if pbGiveItemToPokemon(item, pkmn, self, pkmnid)
              pbRefreshSingle(pkmnid)
            end
          end
        elsif cmdTakeItem >= 0 && command == cmdTakeItem # Take
          if pbTakeItemFromPokemon(pkmn, self)
            pbRefreshSingle(pkmnid)
          end
        elsif cmdMoveItem >= 0 && command == cmdMoveItem # Move
          item = pkmn.item
          itemname = item.name
          @scene.pbSetHelpText(_INTL("Move {1} to where?", itemname))
          oldpkmnid = pkmnid
          loop do
            @scene.pbPreSelect(oldpkmnid)
            pkmnid = @scene.pbChoosePokemon(true, pkmnid)
            break if pkmnid < 0
            newpkmn = @party[pkmnid]
            break if pkmnid == oldpkmnid
            if newpkmn.egg?
              pbDisplay(_INTL("Eggs can't hold items."))
            elsif !newpkmn.hasItem?
              newpkmn.item = item
              pkmn.item = nil
              @scene.pbClearSwitching
              pbRefresh
              pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, itemname))
              break
            elsif GameData::Item.get(newpkmn.item).is_mail?
              pbDisplay(_INTL("{1}'s mail must be removed before giving it an item.", newpkmn.name))
            else
              newitem = newpkmn.item
              newitemname = newitem.name
              if newitem == :LEFTOVERS
                pbDisplay(_INTL("{1} is already holding some {2}.\1", newpkmn.name, newitemname))
              elsif newitemname.starts_with_vowel?
                pbDisplay(_INTL("{1} is already holding an {2}.\1", newpkmn.name, newitemname))
              else
                pbDisplay(_INTL("{1} is already holding a {2}.\1", newpkmn.name, newitemname))
              end
              if pbConfirm(_INTL("Would you like to switch the two items?"))
                newpkmn.item = item
                pkmn.item = newitem
                @scene.pbClearSwitching
                pbRefresh
                pbDisplay(_INTL("{1} was given the {2} to hold.", newpkmn.name, itemname))
                pbDisplay(_INTL("{1} was given the {2} to hold.", pkmn.name, newitemname))
                break
              end
            end
          end
        end
      end
    end
    @scene.pbEndScene
    return nil
  end
end
