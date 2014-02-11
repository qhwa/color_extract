module ColorExtract

  class Palette

    include ColorUtil

    class << self
      def from_colors( colors )
        new.tap do |palette|
          palette.raw_colors = colors.to_a
        end
      end
    end

    attr_accessor :raw_colors

    def initialize( file = nil )
      @analytics = Analytics.new( file ) if file
    end

    # 目前只生成一种配色方案
    # TODO:生成参数可以配置的配色方案
    def palette( accent_seed: nil )
      @palette ||= gen_palette( accent_seed: accent_seed )
    end

    private

      # 目前采用最简单
      def gen_palette( accent_seed: nil )
        colors     = raw_colors || @analytics.valuable_colors.map {|per, c| c }
        main_color = colors.first
        sub_color1 = nil
        sub_color2 = nil

        if accent_seed
          accent_color = accent_seed
        else
          if colors.size > 1
            accent_color = colors.reverse[0..-2].compact.sort_by do |c|
              hue_simi   = hue_similarity(c, main_color)
              simi       = hue_simi > 60 ? -0.5*hue_simi + 120 : 1.5*hue_simi
              l,a,b      = *rgb2lab(c)
              sat        = c.to_hsl.s
              # 按和主要颜色的差异系数由小到大排
              # 饱和度越高、亮度越低的越有可能成为主色
              # simi: 0-90
              # l:    0-100
              # sat:  0-1
              hue_simi + sat * 10 - l * 7.01
          end.last

          else
            accent_color = colors.first
          end
        end

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
          sub1:   sub_color1,
          sub2:   sub_color2,
          accent: accent_color,
          text:   text_color
        }
      end

  end

end
