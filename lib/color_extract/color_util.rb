module ColorExtract

  module ColorUtil

    # 使用 CIE76 公式计算颜色的相似程度
    # 参考: 
    # - [CIELAB](http://en.wikipedia.org/wiki/CIELAB)
    # - [Color Difference](http://en.wikipedia.org/wiki/Color_difference)
    def similarity( color1, color2 )
      l1, a1, b1 = *rgb2lab(color1.to_rgb)
      l2, a2, b2 = *rgb2lab(color2.to_rgb)
      Math.sqrt( (l1-l2)**2 + (a1-a2)**2 + (b1-b2)**2 )
    end

    # 判断两种颜色的色系相似程度
    # 在色盘上越接近，返回值越小
    def hue_similarity( color1, color2 )
      deg1   = color1.to_hsl.h
      deg2   = color2.to_hsl.h
      deg1  += 1 if deg1 < 0
      deg2  += 1 if deg2 < 0
      delta  = (deg1 - deg2).abs
      delta  = 1 - delta if delta > 0.5
      delta * 360
    end
  
    def rgb2lab(color)
      r, g, b = color.r * 255, color.g * 255, color.b * 255
      l       = 0.2126 * r + 0.7152 * g + 0.0722 * b
      a       = 1.4749 * (0.2213 * r - 0.3390 * g + 0.1177 * b) + 128
      b       = 0.6245 * (0.1949 * r + 0.6057 * g - 0.8006 * b) + 128
      [l, a, b]
    end

  end

end
