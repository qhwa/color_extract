module ColorExtract

  module ColorUtil

    # Corresponds roughly to RGB brighter/darker
    K = 18

    # D65 standard referent
    X = 0.950470
    Y = 1
    Z = 1.088830

    # 使用 CIE76 公式计算颜色的相似程度
    # 参考: 
    # - [CIELAB](http://en.wikipedia.org/wiki/CIELAB)
    # - [Color Difference](http://en.wikipedia.org/wiki/Color_difference)
    def similarity( color1, color2, ignore_lightness: false )
      l1, a1, b1 = *rgb2lab(color1.to_rgb)
      l2, a2, b2 = *rgb2lab(color2.to_rgb)
      Math.sqrt( (ignore_lightness ? 0 : (l1-l2)**2) + (a1-a2)**2 + (b1-b2)**2 )
    end

    # Public: 判断两种颜色的色系相似程度
    #         在色盘上越接近，返回值越小
    #
    # Returns 色相距离，0-180之间的角度值
    def hue_similarity( color1, color2 )
      deg1   = color1.to_hsl.h
      deg2   = color2.to_hsl.h
      deg1  += 1 if deg1 < 0
      deg2  += 1 if deg2 < 0
      delta  = (deg1 - deg2).abs
      delta  = 1 - delta if delta > 0.5
      delta * 360
    end
  
    # 来自 github 上的开源项目 chroma
    # https://github.com/gka/chroma.js/blob/master/src/conversions/rgb2lab.coffee
    #
    # color - RGB颜色
    #
    # Returns [l*, a*, b*] 值。
    #         亮度（l*）的范围是（0-100）
    def rgb2lab(color)
      r, g, b = color.r * 255, color.g * 255, color.b * 255
      r = rgb_xyz r
      g = rgb_xyz g
      b = rgb_xyz b
      x = xyz_lab (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / X
      y = xyz_lab (0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / Y
      z = xyz_lab (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / Z
      [116 * y - 16, 500 * (x - y), 200 * (y - z)]
    end

    def rgb_xyz (r)
      if (r /= 255) <= 0.04045 then r / 12.92 else ((r + 0.055) / 1.055) ** 2.4 end
    end

    def xyz_lab (x)
      if x > 0.008856 then x ** (1.0/3) else 7.787037 * x + 4 / 29 end
    end

    # Public: 根据背景色，计算适用于显示其上的文字的颜色
    def readable_textcolor( bg: nil, accent: nil, lock_accent: false)
      l1, a1, b1 = *rgb2lab(bg)
      if accent
        l2, a2, b2 = *rgb2lab(accent)
        return accent if (l1 - l2).abs > 255 * 0.8
      end
      
      # TODO: ajust accent unless lock_accent
      # 白色会显得品质高档，因此尽量使用白色
      if l1 < 75
        Color::RGB.from_html( '#FFFFFF' )
      else
        bg.to_hsl.tap { |c| c.l = 0.1 }.to_rgb
      end
    end

    def pure( color, s: 1, l: 1 )
      color.to_hsl.tap do |c|
        if s
          c.s = s
        else
          c.s += (1 - c.s) * 0.382
        end
        c.l = l if l
      end.to_rgb
    end

    def dither( color )
      color.to_hsl.tap do |c|
        if c.s > 0.8
          c.s -= (c.s) * 0.3
          c.l -= 0.1
        else
          c.s += (1-c.s) * 0.5
        end
      end
    end

    def reverse_color( color )
      color.to_hsl.tap do |c|
        # 色盘旋转60度
        h = c.h + 1.0/6
        h -= 1 if h > 1
        c.h = h
      end.to_rgb
    end

    def darken( hsl_color, percent )
      hsl_color.tap { |c| darken!( c, percent ) }
    end

    def darken!( hsl_color, percent )
      l = hsl_color.l
      hsl_color.l -= (1-l) * percent
    end

    def lighten( hsl_color, percent )
      hsl_color.tap { |c| lighten!( c, percent ) }
    end

    def lighten!( hsl_color, percent )
      l = hsl_color.l
      hsl_color.l += l * percent
    end

  end

end
