#===============================================================================
# ** Game_Temp
#-------------------------------------------------------------------------------
#  This class handles temporary data that is not included with save data.
#  Refer to "$game_temp" for the instance of this class.
#===============================================================================
class Game_Temp
  attr_accessor :message_window_showing   # message window showing
  attr_accessor :common_event_id          # common event ID
  attr_accessor :in_battle                # in-battle flag
  attr_accessor :battle_abort             # battle flag: interrupt
  attr_accessor :battleback_name          # battleback file name
  attr_accessor :in_menu                  # menu is open
  attr_accessor :menu_beep                # menu: play sound effect flag
  attr_accessor :menu_calling             # menu calling flag
  attr_accessor :debug_calling            # debug calling flag
  attr_accessor :player_transferring      # player place movement flag
  attr_accessor :player_new_map_id        # player destination: map ID
  attr_accessor :player_new_x             # player destination: x-coordinate
  attr_accessor :player_new_y             # player destination: y-coordinate
  attr_accessor :player_new_direction     # player destination: direction
  attr_accessor :transition_processing    # transition processing flag
  attr_accessor :transition_name          # transition file name
  attr_accessor :to_title                 # return to title screen flag
  attr_accessor :fadestate                # for sprite hashes
  attr_accessor :background_bitmap
  attr_accessor :mart_prices
  attr_accessor :fromkurayshop
  attr_accessor :unimportedSprites
  attr_accessor :nb_imported_sprites
  attr_accessor :loading_screen
  attr_accessor :custom_sprites_list
  attr_accessor :base_sprites_list
  attr_accessor :moving_furniture
  attr_accessor :moving_furniture_oldPlayerPosition
  attr_accessor :moving_furniture_oldItemPosition
  attr_accessor :visitor_secret_bases
  attr_accessor :talking_npc_id
  attr_accessor :dialog_context
  attr_accessor :active_event_finalizer
  attr_accessor :surf_patches
  attr_accessor :transfer_box_autosave
  attr_accessor :must_save_now
  attr_accessor :original_direction
  attr_accessor :temp_waterfall
  attr_accessor :water_plane
  attr_accessor :water_plane2

  #-----------------------------------------------------------------------------
  # * Object Initialization
  #-----------------------------------------------------------------------------
  def initialize
    @message_window_showing = false
    @common_event_id        = 0
    @in_battle              = false
    @battle_abort           = false
    @battleback_name        = ''
    @in_menu                = false
    @menu_beep              = false
    @menu_calling           = false
    @debug_calling          = false
    @player_transferring    = false
    @player_new_map_id      = 0
    @player_new_x           = 0
    @player_new_y           = 0
    @player_new_direction   = 0
    @transition_processing  = false
    @transition_name        = ""
    @to_title               = false
    @fadestate              = 0
    @background_bitmap      = nil
    @message_window_showing = false
    @transition_processing  = false
    @mart_prices            = {}
    @fromkurayshop          = nil
    @unimportedSprites      = nil
    @nb_imported_sprites    = 0
    @loading_screen         = nil
    @custom_sprites_list    = {}
    @base_sprites_list      = {}
    @moving_furniture       = nil
    @moving_furniture_oldPlayerPosition = nil
    @moving_furniture_oldItemPosition   = nil
    @visitor_secret_bases   = []
    @talking_npc_id         = nil
    @dialog_context         = {}
    @active_event_finalizer = nil
    @surf_patches           = []
    @transfer_box_autosave  = false
    @must_save_now          = false
    @original_direction     = nil
    @temp_waterfall         = nil
    @water_plane            = nil
    @water_plane2           = nil
  end

  def clear_mart_prices
    @mart_prices = {}
  end
end
