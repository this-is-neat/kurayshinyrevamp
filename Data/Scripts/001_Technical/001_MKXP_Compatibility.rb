# Using mkxp-z v2.2.0 - https://gitlab.com/mkxp-z/mkxp-z/-/releases/v2.2.0
$VERBOSE = nil
Font.default_shadow = false if Font.respond_to?(:default_shadow)
Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8
Graphics.frame_rate = 40

def pbSetWindowText(string)
  System.set_window_title(string || System.game_title)
end

def getPathForShinyCache(path)
  originfolder = "z_"
  if path.include?("CustomBattlers/indexed")
    originfolder = "c_"
  elsif path.include?("BaseSprites")
    originfolder = "b_"
  elsif path.include?("Imported")
    originfolder = "i_"
  elsif path.include?("Graphics/Battlers")
    originfolder = "a_"
  elsif path.include?("Graphics/MysteryGifts")
    originfolder = "m_"
  end
  return originfolder
end

def checkDirectory(directory)
  Dir.mkdir(directory) unless File.exists?(directory)
end

def kurayKRSfunc1(krsarray)
  kurayRNG = rand(1..596)
  if kurayRNG <= 512
    krsarray.push(0)
  elsif kurayRNG <= 576
    krsarray.push(1)
  elsif kurayRNG <= 584
    krsarray.push(2)
  elsif kurayRNG <= 592
    krsarray.push(3)
  else
    krsarray.push(4)
  end
  return krsarray
end

def kurayKRSfunc2(krsarray)
  kurayRNG = rand(1..596)
  if kurayRNG <= 512
    krsarray.push(0)
  elsif kurayRNG <= 576
    krsarray.push(rand(-50..50))
  elsif kurayRNG <= 592
    krsarray.push(rand(-100..100))
  else
    krsarray.push(rand(-200..200))
  end
  return krsarray
end

def kurayKRSfunc3(krsarray)
  kurayRNG = rand(1..52)
  if kurayRNG <= 32
    krsarray.push(0)
  elsif kurayRNG <= 48
    krsarray.push(1)
  else
    krsarray.push(2)
  end
  return krsarray
end

def kurayKRSmake
  krsarray = []
  krs_functions = [
    method(:kurayKRSfunc1),
    method(:kurayKRSfunc1),
    method(:kurayKRSfunc1),
    method(:kurayKRSfunc2),
    method(:kurayKRSfunc2),
    method(:kurayKRSfunc2),
    method(:kurayKRSfunc3),
    method(:kurayKRSfunc3),
    method(:kurayKRSfunc3)
  ]
  krs_functions.each { |func| krsarray = func.call(krsarray) }
  return krsarray.clone
end

def kurayRNGforChannels
  if $PokemonSystem.shinyadvanced != nil && $PokemonSystem.shinyadvanced != 2
    kurayRNG = rand(0..10000)
    if kurayRNG < 5
      return rand(0..11)
    elsif kurayRNG < 41
      return rand(0..8)
    elsif kurayRNG < 2041
      return rand(0..5)
    else
      return rand(0..2)
    end
  end

  kurayRNG = rand(0..24632)
  if kurayRNG < 1
    return rand(0..25)
  elsif kurayRNG < 801
    return rand(0..19)
  elsif kurayRNG < 804
    return rand(0..13)
  elsif kurayRNG < 2204
    return rand(0..12)
  elsif kurayRNG < 2212
    return rand(0..11)
  elsif kurayRNG < 2232
    return rand(0..8)
  elsif kurayRNG < 7832
    return rand(0..5)
  else
    return rand(0..2)
  end
end

def kurayGetCustomSprite(dex_number, usedefault = 0)
  return nil if dex_number.nil?
  return nil unless usedefault.is_a?(Integer)
  return nil
end

class Bitmap
  attr_accessor :storedPath

  alias mkxp_draw_text draw_text unless method_defined?(:mkxp_draw_text)

  def draw_text(x, y, width, height, text, align = 0)
    if x.is_a?(Rect)
      x.y -= (@text_offset_y || 0)
      # rect, string & alignment
      mkxp_draw_text(x, y, width)
    else
      y -= (@text_offset_y || 0)
      height = text_size(text).height
      mkxp_draw_text(x, y, width, height, text, align)
    end
  end
end

module Graphics
  def self.delta_s
    return self.delta.to_f / 1_000_000
  end
end

def pbSetResizeFactor(factor)
  if !$ResizeInitialized
    Graphics.resize_screen(Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)
    $ResizeInitialized = true
  end
  if factor < 0 || factor == 4
    Graphics.fullscreen = true if !Graphics.fullscreen
  else
    Graphics.fullscreen = false if Graphics.fullscreen
    Graphics.scale = (factor + 1) * 0.5
    Graphics.center
  end
end
