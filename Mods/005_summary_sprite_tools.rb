class PokemonPokedexInfo_Scene
  def drawPageForms()
    @sprites["background"].setBitmap(_INTL("Graphics/Pictures/Pokedex/bg_forms"))
    overlay = @sprites["overlay"].bitmap
    base = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    textpos = [[_INTL("Use: Sprite options"), 16, Graphics.height - 34, 0, base, shadow]]
    pbDrawTextPositions(overlay, textpos)

    @selected_index = 0 if !@selected_index
    update_displayed
  end

  def selected_sprite_path
    return nil if !@available || !@available[@selected_index]
    return @available[@selected_index]
  end

  def resolved_selected_sprite_path
    sprite_path = selected_sprite_path
    return nil if !sprite_path
    resolved_path = pbResolveBitmap(sprite_path)
    return nil if !resolved_path
    return File.expand_path(resolved_path)
  end

  def selected_sprite_deletable?
    sprite_path = selected_sprite_path
    return false if !sprite_path
    return false if !resolved_selected_sprite_path
    normalized_path = sprite_path.tr("\\", "/")
    return normalized_path.start_with?(Settings::CUSTOM_BASE_SPRITES_FOLDER) ||
           normalized_path.start_with?(Settings::CUSTOM_BATTLERS_FOLDER_INDEXED)
  end

  def clear_sprite_substitutions(sprite_path)
    return if !$PokemonGlobal || !$PokemonGlobal.alt_sprite_substitutions
    $PokemonGlobal.alt_sprite_substitutions.delete_if { |_key, value| value == sprite_path }
  end

  def refresh_available_sprites
    @available = PokedexUtils.pbGetAvailableAlts(@species, @formIndex)
    setAvailableBitmaps(@available)
    @selected_index = @available.length - 1 if @selected_index >= @available.length
    @selected_index = 0 if @selected_index < 0
  end

  def open_selected_sprite_directory
    resolved_path = resolved_selected_sprite_path
    if !resolved_path || !File.file?(resolved_path)
      pbMessage(_INTL("This sprite file could not be found on disk."))
      return
    end

    opened = false
    if RUBY_PLATFORM =~ /mswin|mingw|win/i || (ENV["OS"] =~ /Windows/i rescue false)
      windows_path = resolved_path.gsub("/", "\\")
      opened = system("explorer /select,\"#{windows_path}\"")
    elsif RUBY_PLATFORM =~ /darwin/i
      opened = system("open -R \"#{resolved_path}\"")
    else
      opened = system("xdg-open \"#{File.dirname(resolved_path)}\"")
    end
    return if opened

    Input.clipboard = File.dirname(resolved_path)
    pbMessage(_INTL("The folder could not be opened."))
    pbMessage(_INTL("The folder path was copied to the clipboard instead."))
  end

  def delete_selected_sprite
    sprite_path = selected_sprite_path
    resolved_path = resolved_selected_sprite_path
    if !sprite_path || !resolved_path || !File.file?(resolved_path)
      pbMessage(_INTL("This sprite file could not be found on disk."))
      return false
    end
    if !selected_sprite_deletable?
      pbMessage(_INTL("Only local custom sprites can be deleted from here."))
      return false
    end

    confirm_text = is_main_sprite(@selected_index) ?
      _INTL("Delete this sprite and fall back to another available sprite?") :
      _INTL("Delete this sprite file?")
    return false if !pbConfirmMessage(confirm_text)

    begin
      File.delete(resolved_path)
      clear_sprite_substitutions(sprite_path)
      refresh_available_sprites
      if @available.empty?
        pbMessage(_INTL("No other sprites are available for this Pokemon."))
        return true
      end
      update_displayed
      pbMessage(_INTL("The sprite was deleted."))
      return true
    rescue => e
      echoln(e.message)
      pbMessage(_INTL("The sprite could not be deleted."))
    end
    return false
  end

  def manage_selected_sprite(brief = false)
    Input.update
    command = pbShowCommands(nil, [
      _INTL("Use this sprite"),
      _INTL("Delete sprite"),
      _INTL("Open sprite folder"),
      _INTL("Cancel")
    ], -1)
    return false if command < 0 || command == 3
    if command == 0
      return select_sprite(brief)
    elsif command == 1
      delete_selected_sprite
    elsif command == 2
      open_selected_sprite_directory
    end
    return false
  end

  def pbChooseAlt(brief = false)
    loop do
      @sprites["rightarrow"].visible = true
      @sprites["leftarrow"].visible = true
      if @forms_list.length >= 1
        @sprites["uparrow"].visible = true
        @sprites["downarrow"].visible = true
      end
      multiple_forms = @forms_list.length > 0
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::LEFT)
        pbPlayCursorSE
        @selected_index -= 1
        if @selected_index < 0
          @selected_index = @available.size - 1
        end
        update_displayed
      elsif Input.trigger?(Input::RIGHT)
        pbPlayCursorSE
        @selected_index += 1
        if @selected_index > @available.size - 1
          @selected_index = 0
        end
        update_displayed
      elsif Input.trigger?(Input::UP) && multiple_forms
        pbPlayCursorSE
        @formIndex += 1
        if @formIndex > @forms_list.length
          @formIndex = 0
        end
        @available = pbGetAvailableForms()
        @selected_index = 0
        update_displayed
      elsif Input.trigger?(Input::DOWN) && multiple_forms
        pbPlayCursorSE
        @formIndex -= 1
        if @formIndex < 0
          @formIndex = @forms_list.length
        end
        @available = pbGetAvailableForms()
        @selected_index = 0
        update_displayed
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        if manage_selected_sprite(brief)
          @endscene = true
          break
        end
      end
    end
    @sprites["uparrow"].visible = false
    @sprites["downarrow"].visible = false
  end
end