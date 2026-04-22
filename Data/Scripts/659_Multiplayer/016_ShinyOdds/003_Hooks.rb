#===============================================================================
# MODULE: Shiny Odds Tracking — Creation Hooks
#===============================================================================
# Hooks into all Pokemon creation/catch points to stamp shiny odds.
# Runs AFTER Family assignment (016 loads after 008) so family data is
# already set on the Pokemon when we stamp.
#
# Hook points:
#   1. Wild catches   — pbRecordAndStoreCaughtPokemon (context :wild)
#   2. Breeding       — pbDayCareGenerateEgg (context :breeding)
#   3. K-eggs         — kurayeggs_triggereggitem + pbAddPokemon (context :kegg)
#   4. Cases          — KIFCases.award_pokemon (context :default)
#===============================================================================

# ── 1. Wild catch hook ──────────────────────────────────────────────────────
module MultiplayerCatchReports
  @pending_messages = []

  module_function

  def enabled?
    return false unless defined?(MultiplayerClient) && MultiplayerClient.instance_variable_get(:@connected)
    return false unless defined?($PokemonSystem) && $PokemonSystem
    ($PokemonSystem.mp_catch_chat_enabled || 0) == 1
  rescue
    false
  end

  def announce_catches(caught_refs)
    return unless enabled?
    Array(caught_refs).each do |pkmn|
      next unless own_catch?(pkmn)
      message = build_message(pkmn)
      next if message.to_s.empty?
      enqueue_message(message)
    end
  rescue
    nil
  end

  def own_catch?(pkmn)
    return true unless defined?(CoopBattleState) && CoopBattleState.in_coop_battle?
    my_sid = (MultiplayerClient.session_id rescue nil).to_s
    return false if my_sid.empty?
    catcher_sid = (pkmn.instance_variable_get(:@coop_catcher_sid) rescue nil).to_s
    return false if catcher_sid.empty?
    catcher_sid == my_sid
  rescue
    false
  end

  def build_message(pkmn)
    return nil unless pkmn
    species_name = begin
      pkmn.speciesName
    rescue
      GameData::Species.get(pkmn.species).real_name rescue pkmn.name
    end
    return nil if species_name.to_s.strip.empty?

    descriptor = []
    descriptor << "shiny" if pkmn.shiny? || (pkmn.respond_to?(:fakeshiny?) && pkmn.fakeshiny?)
    prefix = descriptor.empty? ? "" : "#{descriptor.join(' ')} "
    "caught a #{prefix}Lv.#{pkmn.level} #{species_name}!"
  rescue
    nil
  end

  def enqueue_message(text)
    clean = sanitize_message(text)
    return if clean.empty?
    @pending_messages ||= []
    @pending_messages << clean
    @pending_messages.shift while @pending_messages.length > 20
  rescue
    nil
  end

  def flush_pending
    @pending_messages ||= []
    return if @pending_messages.empty?
    unless enabled?
      @pending_messages.clear
      return
    end
    return if defined?($game_temp) && $game_temp && $game_temp.in_battle

    pending = @pending_messages.dup
    @pending_messages.clear
    pending.each { |message| send_global(message) }
  rescue
    nil
  end

  def send_global(text)
    return unless defined?(MultiplayerClient)
    clean = sanitize_message(text)
    return if clean.empty?
    MultiplayerClient.send_data("CHAT_GLOBAL:#{clean}")
  rescue
    nil
  end

  def sanitize_message(text)
    if defined?(ChatCommands) && ChatCommands.respond_to?(:sanitize)
      ChatCommands.sanitize(text)
    else
      text.to_s.gsub(/[\r\n\x00|]/, "").strip[0..149]
    end
  rescue
    ""
  end
end

class PokeBattle_Battle
  alias shiny_odds_original_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon

  def pbRecordAndStoreCaughtPokemon
    # Save refs before chain processes & clears @caughtPokemon
    caught_refs = @caughtPokemon.dup

    # Run chain: Family assigns → Coop processes → Vanilla stores & clears
    shiny_odds_original_pbRecordAndStoreCaughtPokemon

    # Stamp odds on caught shinies — only when connected to server
    return unless defined?(MultiplayerClient) && MultiplayerClient.instance_variable_get(:@connected)
    caught_refs.each do |pkmn|
      next unless pkmn.shiny? || (pkmn.respond_to?(:fakeshiny?) && pkmn.fakeshiny?)
      next if pkmn.shiny_catch_odds  # already stamped (shouldn't happen)

      # Detect PokeRadar chain — shiny grass tiles force shininess
      if defined?($PokemonTemp) && $PokemonTemp.pokeradar &&
         $PokemonTemp.pokeradar[2] && $PokemonTemp.pokeradar[2] > 0
        ShinyOddsTracker.catch_context = :pokeradar
        ShinyOddsTracker.pokeradar_chain = $PokemonTemp.pokeradar[2]
      else
        ShinyOddsTracker.catch_context = :wild
      end

      _stamp_shiny_odds(pkmn)
      ShinyOddsTracker.reset_context
    end
  end

  private

  def _stamp_shiny_odds(pkmn)
    pkmn.shiny_catch_odds = ShinyOddsTracker.calculate_odds

    # Stamp family rate if this shiny has a family assigned
    if pkmn.respond_to?(:has_family_data?) && pkmn.has_family_data?
      pkmn.family_catch_rate = ShinyOddsTracker.calculate_family_rate
    end

    # Request server stamp (async)
    ShinyOddsTracker.request_server_stamp(pkmn)
  end
end

# ── 2. Breeding hook ────────────────────────────────────────────────────────
class PokeBattle_Battle
  unless method_defined?(:mp_catch_reports_original_pbRecordAndStoreCaughtPokemon)
    alias mp_catch_reports_original_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon
  end

  def pbRecordAndStoreCaughtPokemon
    caught_refs = @caughtPokemon ? @caughtPokemon.dup : []
    result = mp_catch_reports_original_pbRecordAndStoreCaughtPokemon
    MultiplayerCatchReports.announce_catches(caught_refs)
    result
  end
end

class Scene_Map
  unless method_defined?(:mp_catch_reports_original_update)
    alias mp_catch_reports_original_update update
  end

  def update
    mp_catch_reports_original_update
    MultiplayerCatchReports.flush_pending if defined?(MultiplayerCatchReports)
  end
end

# Hook pbDayCareGenerateEgg to stamp breeding odds on shiny eggs.
# The egg's shininess is determined during generation (Masuda + Charm rerolls).
alias shiny_odds_original_pbDayCareGenerateEgg pbDayCareGenerateEgg

def pbDayCareGenerateEgg
  # Skip shiny odds stamping when offline
  unless defined?(MultiplayerClient) && MultiplayerClient.instance_variable_get(:@connected)
    shiny_odds_original_pbDayCareGenerateEgg
    return
  end

  # Calculate extra rerolls BEFORE the egg is generated
  # (same logic as the daycare code: +5 Masuda, +2 Shiny Charm)
  extra_rolls = 0
  if $PokemonGlobal.daycare[0][0] && $PokemonGlobal.daycare[1][0]
    father = $PokemonGlobal.daycare[0][0]
    mother = $PokemonGlobal.daycare[1][0]
    extra_rolls += 5 if father.owner.language != mother.owner.language
    extra_rolls += 2 if GameData::Item.exists?(:SHINYCHARM) && ($PokemonBag.pbHasItem?(:SHINYCHARM) rescue false)
  end

  ShinyOddsTracker.catch_context = :breeding
  ShinyOddsTracker.breeding_extra_rolls = extra_rolls

  # Find party size before generation to identify the new egg after
  party_before = $Trainer.party.length

  shiny_odds_original_pbDayCareGenerateEgg

  # The new egg is the last Pokemon in the party (if party grew)
  if $Trainer.party.length > party_before
    egg = $Trainer.party.last
    if egg && (egg.shiny? || (egg.respond_to?(:fakeshiny?) && egg.fakeshiny?))
      egg.shiny_catch_odds = ShinyOddsTracker.calculate_odds
      ShinyOddsTracker.request_server_stamp(egg)
    end
  end

  ShinyOddsTracker.reset_context
end

# ── 3. K-egg hook ───────────────────────────────────────────────────────────
# Hook kurayeggs_triggereggitem to stamp K-egg odds on shiny Pokemon.
# 201_Kuray loads before 659_Multiplayer, so the method always exists.
#
# K-eggs use pbAddPokemon which sends to PC if party is full, so we can't
# rely on party size. Instead, hook pbAddPokemon to stamp during :kegg context.
alias shiny_odds_original_pbAddPokemon pbAddPokemon

def pbAddPokemon(pkmn, level = 1, see_form = true, dontRandomize = false, variableToSave = nil)
  result = shiny_odds_original_pbAddPokemon(pkmn, level, see_form, dontRandomize, variableToSave)

  # Stamp shiny odds on any Pokemon added while in :kegg context
  # Only when connected and pbAddPokemon succeeded
  if result && ShinyOddsTracker.catch_context == :kegg && pkmn.is_a?(Pokemon)
    if defined?(MultiplayerClient) && MultiplayerClient.instance_variable_get(:@connected)
      if pkmn.shiny? || (pkmn.respond_to?(:fakeshiny?) && pkmn.fakeshiny?)
        unless pkmn.shiny_catch_odds  # not already stamped
          pkmn.shiny_catch_odds = ShinyOddsTracker.calculate_odds
          ShinyOddsTracker.request_server_stamp(pkmn)
        end
      end
    end
  end

  result
end

begin
  alias shiny_odds_original_kurayeggs_triggereggitem kurayeggs_triggereggitem

  def kurayeggs_triggereggitem(id, itemid)
    ShinyOddsTracker.catch_context = :kegg
    result = shiny_odds_original_kurayeggs_triggereggitem(id, itemid)
    ShinyOddsTracker.reset_context
    result
  end
rescue NameError
  # kurayeggs_triggereggitem not defined (K-eggs not installed)
end

# ── 4. Case hook ────────────────────────────────────────────────────────────
# Hook KIFCases.award_pokemon for PokéCase drops.
if defined?(KIFCases)
  module KIFCases
    class << self
      alias shiny_odds_original_award_pokemon award_pokemon

      def award_pokemon(species_sym)
        pkmn = shiny_odds_original_award_pokemon(species_sym)

        if defined?(MultiplayerClient) && MultiplayerClient.instance_variable_get(:@connected)
          if pkmn && (pkmn.shiny? || (pkmn.respond_to?(:fakeshiny?) && pkmn.fakeshiny?))
            ShinyOddsTracker.catch_context = :default
            pkmn.shiny_catch_odds = ShinyOddsTracker.calculate_odds
            ShinyOddsTracker.request_server_stamp(pkmn)
            ShinyOddsTracker.reset_context
          end
        end

        pkmn
      end
    end
  end
end

# ── 5. Shedinja duplicate hook ────────────────────────────────────────────
# When Nincada evolves, pbDuplicatePokemon clones the original (which may
# be a fused shiny). The clone inherits all stamp data — strip it so the
# duplicate doesn't display odds it didn't earn.
class PokemonEvolutionScene
  class << self
    alias shiny_odds_original_pbDuplicatePokemon pbDuplicatePokemon

    def pbDuplicatePokemon(pkmn, new_species)
      shiny_odds_original_pbDuplicatePokemon(pkmn, new_species)
      # The duplicate is the last Pokemon in the party
      duped = $Trainer.party.last
      return unless duped
      duped.shiny_catch_odds    = nil if duped.respond_to?(:shiny_catch_odds=)
      duped.family_catch_rate   = nil if duped.respond_to?(:family_catch_rate=)
      duped.shiny_odds_stamped  = false if duped.respond_to?(:shiny_odds_stamped=)
      duped.shiny_catch_context = nil if duped.respond_to?(:shiny_catch_context=)
    end
  end
end
