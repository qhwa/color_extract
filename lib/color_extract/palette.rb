module ColorExtract

  class Palette

    include ColorUtil

    def initialize( file )
      @analytics = Analytics.new( file )
    end

    # 目前只生成一种配色方案
    # TODO:生成参数可以配置的配色方案
    def palette
      @palette ||= gen_palette
    end

    private

      # 目前采用最简单
      def gen_palette
        colors       = @analytics.valuable_colors.map {|per, c| c }
        main_color   = try_dither( colors.first )
        sub_color1   = nil
        sub_color2   = nil

        accent_color = colors.reverse[0..-2].map do |c|
          if c
            [c, hue_similarity(c, main_color), c.to_hsl.s]
          end
        end.compact.sort_by {|c, simi, sat| -(((simi/100.0)**3 + (1-sat)**2))}.first[0]

        accent_color = try_dither( accent_color )

        colors[1..-1].each do |c|
          if hue_similarity(c, accent_color ) < 60
            if sub_color1.nil?
              sub_color1 = c.to_hsl.tap do |c|
                c.l = accent_color.to_hsl.l + 0.2
              end.to_rgb
            else
              sub_color2 = c.to_hsl.tap do |c|
                c.l = accent_color.to_hsl.l - 0.2
              end.to_rgb
            end
          end
        end
          
        text_color = readable_textcolor bg: accent_color, accent: main_color
        {
          main:   main_color,
          sub1:   try_dither(sub_color1),
          sub2:   try_dither(sub_color2),
          accent: accent_color,
          text:   text_color
        }
      end

      def try_dither( color )
        color && pure( dither(color), s: nil, l: nil ) #dither( color )
      end

  end

end
