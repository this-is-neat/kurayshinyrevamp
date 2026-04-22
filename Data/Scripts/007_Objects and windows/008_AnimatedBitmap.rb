#===============================================================================
#
#===============================================================================

class ByteWriter
  def initialize(filename)
    @file = File.new(filename, "wb")
  end

  def <<(*data)
    write(*data)
  end

  def write(*data)
    data.each do |e|
      if e.is_a?(Array) || e.is_a?(Enumerator)
        e.each { |item| write(item) }
      elsif e.is_a?(Numeric)
        @file.putc e
      else
        raise "Invalid data for writing.\nData type: #{e.class}\nData: #{e.inspect[0..100]}"
      end
    end
  end

  def write_int(int)
    self << ByteWriter.to_bytes(int)
  end

  def close
    @file.close
    @file = nil
  end

  def self.to_bytes(int)
    return [
      (int >> 24) & 0xFF,
      (int >> 16) & 0xFF,
      (int >> 8) & 0xFF,
      int & 0xFF
    ]
  end
end

class AnimatedBitmap
  attr_reader :path
  attr_reader :filename

  def initialize(file, hue = 0)
    raise "Filename is nil (missing graphic)." if file.nil?
    path = file
    filename = ""
    if file.last != '/' # Isn't just a directory
      split_file = file.split(/[\\\/]/)
      filename = split_file.pop
      path = split_file.join('/') + '/'
    end
    @filename = filename
    @path = path
    if filename[/^\[\d+(?:,\d+)?\]/] # Starts with 1 or 2 numbers in square brackets
      @bitmap = PngAnimatedBitmap.new(path, filename, hue)
    else
      @bitmap = GifBitmap.new(path, filename, hue)
    end
  end

  def setup_from_bitmap(bitmap,hue=0)
    @path = ""
    @filename = ""
    @bitmap = GifBitmap.new("", '', hue)
    @bitmap.bitmap = bitmap;
  end

  def self.from_bitmap(bitmap, hue=0)
    obj = allocate
    obj.send(:setup_from_bitmap, bitmap, hue)
    obj
  end

  def pbSetColor(r = 0, g = 0, b = 0, a = 255)
    color = Color.new(r, g, b, a)
    pbSetColorValue(color)
  end

  def pbSetColorValue(color)
    for i in 0..@bitmap.bitmap.width
      for j in 0..@bitmap.bitmap.height
        if @bitmap.bitmap.get_pixel(i, j).alpha != 0
          @bitmap.bitmap.set_pixel(i, j, color)
        end
      end
    end
  end

  def pbGetRedChannel
    redChannel = []
    for i in 0..@bitmap.bitmap.width
      for j in 0..@bitmap.bitmap.height
        redChannel.push(@bitmap.bitmap.get_pixel(i, j).red)
      end
    end
    return redChannel
  end

  def pbGetBlueChannel
    blueChannel = []
    for i in 0..@bitmap.bitmap.width
      for j in 0..@bitmap.bitmap.height
        blueChannel.push(@bitmap.bitmap.get_pixel(i, j).blue)
      end
    end
    return blueChannel
  end

  def pbGetGreenChannel
    greenChannel = []
    for i in 0..@bitmap.bitmap.width
      for j in 0..@bitmap.bitmap.height
        greenChannel.push(@bitmap.bitmap.get_pixel(i, j).green)
      end
    end
    return greenChannel
  end

  def bitmap_to_png(filename)
    return unless @bitmap
    require 'zlib'
    f = ByteWriter.new(filename)
    f << [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    f << [0x00, 0x00, 0x00, 0x0D]
    headertype = [0x49, 0x48, 0x44, 0x52]
    f << headertype
    headerdata = ByteWriter.to_bytes(@bitmap.width).
      concat(ByteWriter.to_bytes(@bitmap.height)).
      concat([0x08, 0x06, 0x00, 0x00, 0x00])
    f << headerdata
    sum = headertype.concat(headerdata)
    f.write_int Zlib::crc32(sum.pack("C*"))

    data = []
    for y in 0...@bitmap.height
      data << 0x00
      for x in 0...@bitmap.width
        px = @bitmap.bitmap.get_pixel(x, y)
        data << px.red
        data << px.green
        data << px.blue
        data << px.alpha
      end
    end
    smoldata = Zlib::Deflate.deflate(data.pack("C*")).bytes
    f.write_int smoldata.size
    f << [0x49, 0x44, 0x41, 0x54]
    f << smoldata
    f.write_int Zlib::crc32([0x49, 0x44, 0x41, 0x54].concat(smoldata).pack("C*"))

    f << [0x00, 0x00, 0x00, 0x00]
    f << [0x49, 0x45, 0x4E, 0x44]
    f.write_int Zlib::crc32([0x49, 0x45, 0x4E, 0x44].pack("C*"))
    f.close
    return nil
  end

  def shiftCustomColors(rules)
    @bitmap.bitmap.hue_customcolor(rules)
  end

  def shiftAllColors(dex_number, bodyShiny, headShiny)
    if isFusion(dex_number)
      return if !bodyShiny && !headShiny
      body_id = getBodyID(dex_number)
      head_id = getHeadID(dex_number, body_id)
      offsets = [SHINY_COLOR_OFFSETS[body_id], SHINY_COLOR_OFFSETS[head_id]]
    else
      offsets = [SHINY_COLOR_OFFSETS[dex_number]]
    end

    offset = offsets.compact.max_by { |o| o.keys.count }
    return unless offset
    onetime = true
    offset.keys.each do |version|
      value = offset&.dig(version)

      if value.is_a?(String) && onetime
        onetime = false
        shiftCustomColors(GameData::Species.calculateCustomShinyHueOffset(dex_number, bodyShiny, headShiny))
      elsif !value.is_a?(String)
        shiftColors(GameData::Species.calculateShinyHueOffset(dex_number, bodyShiny, headShiny, version))
      end
    end
  end

  def pbGiveFinaleColor(shinyR, shinyG, shinyB, offset, shinyKRS, shinyOmega = {})
    shiny_mode = 0
    if $PokemonSystem
      case $PokemonSystem.pifimprovedshinies
      when 0
        shiny_mode = 0
      when 1
        shiny_mode = 1
      when 2
        shiny_mode = 2
      when 3
        shiny_mode = 3
      end
    end

    dexNum = 1
    body_shiny = false
    head_shiny = false

    force_pif_split = false
    use_pif = 0
    if shinyOmega.has_key?("pif_shiny")
      use_pif = shinyOmega.fetch("pif_shiny", 0)
    end

    if use_pif > 1
      use_pif = 1
    elsif use_pif == 1
      use_pif = 1
      force_pif_split = true
    else
      use_pif = 0
    end

    if shinyOmega.has_key?("dexNum")
      dexNum = shinyOmega.fetch("dexNum", 1)
    end
    if shinyOmega.has_key?("body_shiny")
      body_shiny = shinyOmega.fetch("body_shiny", false)
    end
    if shinyOmega.has_key?("head_shiny")
      head_shiny = shinyOmega.fetch("head_shiny", false)
    end

    shiny_cache_name = "_ps"
    shiny_cache_name += "h" if head_shiny
    shiny_cache_name += "b" if body_shiny

    use_kif = 1
    if shiny_mode == 0
      use_kif = 1
      use_pif = 0 if use_pif == 3
    elsif shiny_mode == 1
      if use_pif == 1 && !force_pif_split
        use_kif = 0
      else
        use_kif = 1
      end
    elsif shiny_mode == 2
      use_pif = 1
      use_kif = 0
    elsif shiny_mode == 3
      use_pif = 0
      use_kif = 1
    end

    use_pif = 1 if use_kif == 0

    @bitmap = nil
    usedoffset = offset
    loadedfromcache = false
    if $PokemonSystem && $PokemonSystem.shiny_cache != 2
      originfolder = getPathForShinyCache(@path)
      checkDirectory("Cache")
      checkDirectory("Cache/Shiny")
      shinyname = "_#{offset + 180}_#{shinyR}_#{shinyG}_#{shinyB}"
      for i in 0..shinyKRS.size - 1
        shinyname += "_#{shinyKRS[i]}"
      end
      shinyname += shiny_cache_name if use_pif == 1 && use_kif == 1
      pathimport = "Cache/Shiny/"
      if use_kif == 0
        checkDirectory("Cache/Shiny/vanilla")
        shinyname = shiny_cache_name
        pathimport = "Cache/Shiny/vanilla/"
      end
      cleanname = @filename[0...-4]
      pathfilename = originfolder + cleanname + shinyname + ".png"
      if File.exists?(pathimport + pathfilename)
        @filename = pathfilename
        @path = pathimport
        usedoffset = 0
        loadedfromcache = true
      end
    end

    usedoffset = 0 if use_pif == 1
    newbitmap = GifBitmap.new(@path, @filename, usedoffset, shinyR, shinyG, shinyB, use_pif, use_kif)
    @bitmap = newbitmap.copy
    recognizeDims()
    if ($PokemonSystem.shinyadvanced != nil && $PokemonSystem.shinyadvanced == 0) || loadedfromcache
      return
    end

    if use_pif == 1
      self.shiftAllColors(dexNum, body_shiny, head_shiny)
      @bitmap.bitmap.hue_change(offset) if use_kif == 1
    end

    if use_kif == 1
      greenShiny = []
      redShiny = []
      blueShiny = []
      greeninclude = [1, 3, 5, 7, 9, 11, 12, 13, 14, 16, 17, 19, 20, 22, 23, 25]
      redinclude = [0, 3, 4, 6, 9, 10, 12, 13, 14, 15, 17, 18, 20, 21, 23, 24]
      blueinclude = [2, 4, 5, 8, 10, 11, 12, 13, 15, 16, 18, 19, 21, 22, 24, 25]
      greenShiny = self.pbGetGreenChannel if greeninclude.include?(shinyR) || greeninclude.include?(shinyB) || greeninclude.include?(shinyG) || shinyKRS[4] > 0
      redShiny = self.pbGetRedChannel if redinclude.include?(shinyR) || redinclude.include?(shinyB) || redinclude.include?(shinyG) || shinyKRS[3] > 0
      blueShiny = self.pbGetBlueChannel if blueinclude.include?(shinyR) || blueinclude.include?(shinyB) || blueinclude.include?(shinyG) || shinyKRS[5] > 0

      if $PokemonSystem.shinyadvanced != nil && $PokemonSystem.shinyadvanced == 2
        redShiny = self.krsapply(redShiny, shinyKRS[3], 0, shinyKRS) if shinyKRS[3] > 0
        greenShiny = self.krsapply(greenShiny, shinyKRS[4], 1, shinyKRS) if shinyKRS[4] > 0
        blueShiny = self.krsapply(blueShiny, shinyKRS[5], 2, shinyKRS) if shinyKRS[5] > 0
      end

      canalRed = self.getChannelGradient(shinyR, redShiny, greenShiny, blueShiny, shinyKRS, 0)
      canalGreen = self.getChannelGradient(shinyG, redShiny, greenShiny, blueShiny, shinyKRS, 1)
      canalBlue = self.getChannelGradient(shinyB, redShiny, greenShiny, blueShiny, shinyKRS, 2)

      for i in 0..@bitmap.bitmap.width
        for j in 0..@bitmap.bitmap.height
          if @bitmap.bitmap.get_pixel(i, j).alpha != 0
            depth = i * (@bitmap.bitmap.height + 1) + j
            @bitmap.bitmap.set_pixel(i, j, Color.new(canalRed[depth], canalGreen[depth], canalBlue[depth], @bitmap.bitmap.get_pixel(i, j).alpha))
          end
        end
      end
    end

    if $PokemonSystem && $PokemonSystem.shiny_cache != 2
      originfolder = getPathForShinyCache(@path)
      checkDirectory("Cache")
      checkDirectory("Cache/Shiny")
      shinyname = "_#{offset + 180}_#{shinyR}_#{shinyG}_#{shinyB}"
      for i in 0..shinyKRS.size - 1
        shinyname += "_#{shinyKRS[i]}"
      end
      shinyname += shiny_cache_name if use_pif == 1 && use_kif == 1
      if use_kif == 0
        checkDirectory("Cache/Shiny/vanilla")
        shinyname = shiny_cache_name
      end
      cleanname = @filename[0...-4]
      if use_kif == 0
        pathexport = "Cache/Shiny/vanilla/" + originfolder + cleanname + shinyname + ".png"
      else
        pathexport = "Cache/Shiny/" + originfolder + cleanname + shinyname + ".png"
      end
      self.bitmap_to_png(pathexport) if !File.exists?(pathexport)
    end
  end

  def krsapply(channel, condif, idcol, shinyKRS)
    timidblack = shinyKRS[idcol + 6]
    if condif == 1
      channel = channel.map { |v| v >= 127 ? v - 127.0 : v }
    elsif condif == 2
      channel = channel.map do |v|
        if ((timidblack == 1 && v > 16) || (timidblack == 2 && v > 42) || (timidblack == 0)) && v <= 127
          v + 127.0
        else
          v
        end
      end
    elsif condif == 3
      channel = channel.map { |v| v >= 127 ? 255.0 - (v - 127.0) : v }
    elsif condif == 4
      channel = channel.map do |v|
        if ((timidblack == 1 && v > 16) || (timidblack == 2 && v > 42) || (timidblack == 0)) && v <= 127
          127.0 - v
        else
          v
        end
      end
    end
    return channel
  end

  def getChannelGradient(shiny, redShiny, greenShiny, blueShiny, shinyKRS, idcol)
    if $PokemonSystem.shinyadvanced != nil && $PokemonSystem.shinyadvanced == 1
      if shiny == 1
        return greenShiny.clone
      elsif shiny == 2
        return blueShiny.clone
      elsif shiny == 0
        return redShiny.clone
      elsif shiny == 3
        return redShiny.clone.zip(greenShiny.clone).map { |r, g| (r + g) / 2 }
      elsif shiny == 4
        return redShiny.clone.zip(blueShiny.clone).map { |r, b| (r + b) / 2 }
      elsif shiny == 5
        return greenShiny.clone.zip(blueShiny.clone).map { |g, b| (g + b) / 2 }
      elsif shiny == 6
        return redShiny.clone.map { |r| 255.0 - r }
      elsif shiny == 7
        return greenShiny.clone.map { |r| 255.0 - r }
      elsif shiny == 8
        return blueShiny.clone.map { |r| 255.0 - r }
      elsif shiny == 9
        colordoing = redShiny.clone.zip(greenShiny.clone).map { |r, g| (r + g) / 2 }
        return colordoing.map { |r| 255.0 - r }
      elsif shiny == 10
        colordoing = redShiny.clone.zip(blueShiny.clone).map { |r, b| (r + b) / 2 }
        return colordoing.map { |r| 255.0 - r }
      elsif shiny == 11
        colordoing = greenShiny.clone.zip(blueShiny.clone).map { |g, b| (g + b) / 2 }
        return colordoing.map { |r| 255.0 - r }
      else
        return redShiny.clone
      end
    end

    timidblack = shinyKRS[idcol + 6]
    redincr = shinyKRS[0].to_f
    greenincr = shinyKRS[1].to_f
    blueincr = shinyKRS[2].to_f
    if shiny == 1
      return greenShiny.clone.map { |value| (value + greenincr).clamp(0, 255) }
    elsif shiny == 2
      return blueShiny.clone.map { |value| (value + blueincr).clamp(0, 255) }
    elsif shiny == 0
      return redShiny.clone.map { |value| (value + redincr).clamp(0, 255) }
    elsif shiny == 3
      return redShiny.clone.zip(greenShiny.clone).map { |r, g| (((r + redincr)).clamp(0, 255) + ((g + greenincr)).clamp(0, 255)) / 2 }
    elsif shiny == 4
      return redShiny.clone.zip(blueShiny.clone).map { |r, b| (((r + redincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255)) / 2 }
    elsif shiny == 5
      return greenShiny.clone.zip(blueShiny.clone).map { |g, b| (((g + greenincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255)) / 2 }
    elsif shiny == 6
      colordoing = redShiny.clone.map { |value| (value + redincr).clamp(0, 255) }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 7
      colordoing = greenShiny.clone.map { |value| (value + greenincr).clamp(0, 255) }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 8
      colordoing = blueShiny.clone.map { |value| (value + blueincr).clamp(0, 255) }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 9
      colordoing = redShiny.clone.zip(greenShiny.clone).map { |r, g| (((r + redincr)).clamp(0, 255) + ((g + greenincr)).clamp(0, 255)) / 2 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 10
      colordoing = redShiny.clone.zip(blueShiny.clone).map { |r, b| (((r + redincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255)) / 2 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 11
      colordoing = greenShiny.clone.zip(blueShiny.clone).map { |g, b| (((g + greenincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255)) / 2 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 12
      return greenShiny.clone.zip(blueShiny.clone, redShiny.clone).map { |g, b, r| (((g + greenincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) + ((r + redincr)).clamp(0, 255)) / 3 }
    elsif shiny == 13
      colordoing = greenShiny.clone.zip(blueShiny.clone, redShiny.clone).map { |g, b, r| (((g + greenincr)).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) + ((r + redincr)).clamp(0, 255)) / 3 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 14
      return redShiny.clone.zip(greenShiny.clone).map { |r, g| (((r + redincr).clamp(0, 255) + ((g + greenincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 15
      return redShiny.clone.zip(blueShiny.clone).map { |r, b| (((r + redincr).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 16
      return greenShiny.clone.zip(blueShiny.clone).map { |g, b| (((g + greenincr).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 17
      return greenShiny.clone.zip(redShiny.clone).map { |g, r| (((g + greenincr).clamp(0, 255) + ((r + redincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 18
      return blueShiny.clone.zip(redShiny.clone).map { |b, r| (((b + blueincr).clamp(0, 255) + ((r + redincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 19
      return blueShiny.clone.zip(greenShiny.clone).map { |b, g| (((b + blueincr).clamp(0, 255) + ((g + greenincr)).clamp(0, 255) * 3)) / 4 }
    elsif shiny == 20
      colordoing = redShiny.clone.zip(greenShiny.clone).map { |r, g| (((r + redincr).clamp(0, 255) + ((g + greenincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 21
      colordoing = redShiny.clone.zip(blueShiny.clone).map { |r, b| (((r + redincr).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 22
      colordoing = greenShiny.clone.zip(blueShiny.clone).map { |g, b| (((g + greenincr).clamp(0, 255) + ((b + blueincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 23
      colordoing = greenShiny.clone.zip(redShiny.clone).map { |g, r| (((g + greenincr).clamp(0, 255) + ((r + redincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 24
      colordoing = blueShiny.clone.zip(redShiny.clone).map { |b, r| (((b + blueincr).clamp(0, 255) + ((r + redincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    elsif shiny == 25
      colordoing = blueShiny.clone.zip(greenShiny.clone).map { |b, g| (((b + blueincr).clamp(0, 255) + ((g + greenincr)).clamp(0, 255) * 3)) / 4 }
      return colordoing.map { |r| ((timidblack == 1 && r > 16) || (timidblack == 2 && r > 42) || (timidblack == 0)) ? 255.0 - r : r }
    else
      return redShiny.clone
    end
  end

  def pbGiveFinaleColorDefault(shinyR, shinyG, shinyB, offset)
    dontmodify = 0
    dontmodify = 1 if shinyR == 0 && shinyG == 1 && shinyB == 2
    @bitmap = nil
    newbitmap = GifBitmap.new(@path, @filename, offset, shinyR, shinyG, shinyB)
    @bitmap = newbitmap.copy
    greenShiny = []
    redShiny = []
    blueShiny = []
    greenShiny = self.pbGetGreenChannel if shinyR == 1 || shinyB == 1 || shinyG == 1
    redShiny = self.pbGetRedChannel if shinyG == 0 || shinyB == 0 || shinyR == 0
    blueShiny = self.pbGetBlueChannel if shinyG == 2 || shinyR == 2 || shinyB == 2
    canalRed = shinyR == 1 ? greenShiny.clone : shinyR == 2 ? blueShiny.clone : redShiny.clone
    canalGreen = shinyG == 1 ? greenShiny.clone : shinyG == 2 ? blueShiny.clone : redShiny.clone
    canalBlue = shinyB == 1 ? greenShiny.clone : shinyB == 2 ? blueShiny.clone : redShiny.clone
    if dontmodify == 0
      for i in 0..@bitmap.bitmap.width
        for j in 0..@bitmap.bitmap.height
          if @bitmap.bitmap.get_pixel(i, j).alpha != 0
            depth = i * (@bitmap.bitmap.height + 1) + j
            @bitmap.bitmap.set_pixel(i, j, Color.new(canalRed[depth], canalGreen[depth], canalBlue[depth], @bitmap.bitmap.get_pixel(i, j).alpha))
          end
        end
      end
    end
  end


  def shiftColors(offset = 0)
    @bitmap.bitmap.hue_change(offset)
  end

  def [](index)
    ; @bitmap[index];
  end

  def width
    @bitmap.bitmap.width;
  end

  def height
    @bitmap.bitmap.height;
  end

  def length
    @bitmap.length;
  end

  def each
    @bitmap.each { |item| yield item };
  end

  def bitmap
    @bitmap.bitmap;
  end

  def bitmap=(bitmap)
    @bitmap.bitmap = bitmap;
  end

  def currentIndex
    @bitmap.currentIndex;
  end

  def totalFrames
    @bitmap.totalFrames;
  end

  def disposed?
    @bitmap.disposed?;
  end

  def update
    @bitmap.update;
  end

  def dispose
    @bitmap.dispose;
  end

  def deanimate
    @bitmap.deanimate;
  end

  def copy
    @bitmap.copy;
  end

  def scale_bitmap(scale)
    return if scale == 1

    actual_bitmap = @bitmap.respond_to?(:bitmap) ? @bitmap.bitmap : @bitmap
    return unless actual_bitmap.respond_to?(:width) && actual_bitmap.respond_to?(:height)

    new_width = (actual_bitmap.width * scale).floor
    new_height = (actual_bitmap.height * scale).floor
    return if new_width <= 0 || new_height <= 0

    destination_rect = Rect.new(0, 0, new_width, new_height)
    source_rect = Rect.new(0, 0, actual_bitmap.width, actual_bitmap.height)
    new_bitmap = Bitmap.new(new_width, new_height)
    new_bitmap.stretch_blt(destination_rect, actual_bitmap, source_rect)

    if @bitmap.respond_to?(:bitmap)
      @bitmap.bitmap = new_bitmap
    else
      @bitmap = new_bitmap
    end
  end

  def recognizeDims
    if @bitmap.bitmap.width == 96 && @bitmap.bitmap.height == 96
      scale_bitmap(3)
    elsif @bitmap.bitmap.width != 288 && @bitmap.bitmap.height != 288
      echoln("not a 96x96 or 288x288 sprite")
      puts "#{@path}#{@filename}"
      puts "Width: #{@bitmap.bitmap.width}"
      puts "Height: #{@bitmap.bitmap.height}"
    end
    return self
  end

  def mirror
    mirror_horizontally
  end

  def mirror_horizontally
    bmp = @bitmap.bitmap
    half_width = bmp.width / 2
    height = bmp.height

    (0...half_width).each do |x|
      (0...height).each do |y|
        left_pixel  = bmp.get_pixel(x, y)
        right_pixel = bmp.get_pixel(bmp.width - 1 - x, y)

        bmp.set_pixel(x, y, right_pixel)
        bmp.set_pixel(bmp.width - 1 - x, y, left_pixel)
      end
    end
  end


  def mirror_vertically
    bmp = @bitmap.bitmap
    width = bmp.width
    half_height = bmp.height / 2

    (0...half_height).each do |y|
      (0...width).each do |x|
        top_pixel    = bmp.get_pixel(x, y)
        bottom_pixel = bmp.get_pixel(x, bmp.height - 1 - y)

        bmp.set_pixel(x, y, bottom_pixel)
        bmp.set_pixel(x, bmp.height - 1 - y, top_pixel)
      end
    end
  end



  # def mirror
  #   @bitmap.bitmap
  # end

end


#===============================================================================
#
#===============================================================================
class PngAnimatedBitmap
  attr_accessor :frames

  # Creates an animated bitmap from a PNG file.
  def initialize(dir, filename, hue = 0)
    @frames = []
    @currentFrame = 0
    @framecount = 0
    panorama = RPG::Cache.load_bitmap(dir, filename, hue)
    if filename[/^\[(\d+)(?:,(\d+))?\]/] # Starts with 1 or 2 numbers in brackets
      # File has a frame count
      numFrames = $1.to_i
      delay = $2.to_i
      delay = 10 if delay == 0
      raise "Invalid frame count in #{filename}" if numFrames <= 0
      raise "Invalid frame delay in #{filename}" if delay <= 0
      if panorama.width % numFrames != 0
        raise "Bitmap's width (#{panorama.width}) is not divisible by frame count: #{filename}"
      end
      @frameDelay = delay
      subWidth = panorama.width / numFrames
      for i in 0...numFrames
        subBitmap = BitmapWrapper.new(subWidth, panorama.height)
        subBitmap.blt(0, 0, panorama, Rect.new(subWidth * i, 0, subWidth, panorama.height))
        @frames.push(subBitmap)
      end
      panorama.dispose
    else
      @frames = [panorama]
    end
  end

  def [](index)
    return @frames[index]
  end

  def width
    self.bitmap.width;
  end

  def height
    self.bitmap.height;
  end

  def deanimate
    for i in 1...@frames.length
      @frames[i].dispose
    end
    @frames = [@frames[0]]
    @currentFrame = 0
    return @frames[0]
  end

  def bitmap
    return @frames[@currentFrame]
  end

  def currentIndex
    return @currentFrame
  end

  def frameDelay(_index)
    return @frameDelay
  end

  def length
    return @frames.length
  end

  def each
    @frames.each { |item| yield item }
  end

  def totalFrames
    return @frameDelay * @frames.length
  end

  def disposed?
    return @disposed
  end

  def update
    return if disposed?
    if @frames.length > 1
      @framecount += 1
      if @framecount >= @frameDelay
        @framecount = 0
        @currentFrame += 1
        @currentFrame %= @frames.length
      end
    end
  end

  def dispose
    if !@disposed
      @frames.each { |f| f.dispose }
    end
    @disposed = true
  end

  def copy
    x = self.clone
    x.frames = x.frames.clone
    for i in 0...x.frames.length
      x.frames[i] = x.frames[i].copy
    end
    return x
  end
end

#===============================================================================
#
#===============================================================================
class GifBitmap
  attr_accessor :bitmap
  attr_accessor :rcode
  attr_accessor :gcode
  attr_accessor :bcode
  attr_reader :loaded_from_cache
  # Creates a bitmap from a GIF file. Can also load non-animated bitmaps.
  def initialize(dir, filename, hue = 0, rcode = 0, gcode = 1, bcode = 2, pifshiny = 0, kifshiny = 0)
    @bitmap = nil
    @disposed = false
    @loaded_from_cache = false
    @rcode = 0
    @gcode = 1
    @bcode = 2
    filename = "" if !filename
    begin
      @bitmap = RPG::Cache.load_bitmap(dir, filename, hue, rcode, gcode, bcode, pifshiny, kifshiny)
      @loaded_from_cache = true
    rescue
      @bitmap = nil
    end
    @bitmap = BitmapWrapper.new(32, 32) if @bitmap.nil?
    @bitmap.play if @bitmap&.animated?
  end

  def [](_index)
    return @bitmap
  end

  def deanimate
    @bitmap&.goto_and_stop(0) if @bitmap&.animated?
    return @bitmap
  end

  def currentIndex
    return @bitmap&.current_frame || 0
  end

  def length
    return @bitmap&.frame_count || 1
  end

  def each
    yield @bitmap
  end

  def totalFrames
    f_rate = @bitmap.frame_rate
    f_rate = 1 if f_rate.nil? || f_rate == 0
    return (@bitmap) ? (@bitmap.frame_count / f_rate).floor : 1
  end

  def disposed?
    return @disposed
  end

  def width
    return @bitmap&.width || 0
  end

  def height
    return @bitmap&.height || 0
  end

  # Gifs are animated automatically by mkxp-z. This function does nothing.
  def update; end

  def dispose
    return if @disposed
    @bitmap.dispose
    @disposed = true
  end

  def copy
    x = self.clone
    x.bitmap = @bitmap.copy if @bitmap
    return x
  end
end

#===============================================================================
#
#===============================================================================
def pbGetTileBitmap(filename, tile_id, hue, width = 1, height = 1)
  return RPG::Cache.tileEx(filename, tile_id, hue, width, height) { |f|
    AnimatedBitmap.new("Graphics/Tilesets/" + filename).deanimate
  }
end

def pbGetTileset(name, hue = 0)
  return AnimatedBitmap.new("Graphics/Tilesets/" + name, hue).deanimate
end

def pbGetAutotile(name, hue = 0)
  return AnimatedBitmap.new("Graphics/Autotiles/" + name, hue).deanimate
end

def pbGetAnimation(name, hue = 0)
  return AnimatedBitmap.new("Graphics/Animations/" + name, hue).deanimate
end
