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

    attr_accessor :raw_colors, :main_color, :max_pri_brightness

    def initialize( file = nil )
      @analytics = Analytics.new( file ) if file
    end

    # 目前只生成一种配色方案
    # TODO:生成参数可以配置的配色方案
    def palette( accent_seed: nil )
      palettes( count: 1, accent_seed: accent_seed ).first
    end

    def palettes( opts={} )
      @raw_colors ||= @analytics.valuable_colors.map {|per, c| c }
      @palettes   ||= gen_palettes( opts )
      @palettes
    end

    private

      # 目前采用最简单
      def gen_palettes( count: 1, accent_seed: nil, max_pri_brightness: 1 )
        count               = 1 if accent_seed
        @max_pri_brightness = max_pri_brightness
        @main_color         = most_possible_main_color

        count.times.map do |i|
          gen_palette( accent_seed: accent_seed, fewest_index: i )
        end
      end

      def most_possible_main_color
        raw_colors.size > 0 ? raw_colors.first : Color::RGB.from_html( '#CCCCCC' )
      end

      # Private: 生成配色方案
      #
      # accent_seed:  指定的 primary 颜色
      # fewest_index: 指定倒数第几个最少的颜色
      #               0 - 最少的颜色;
      #               1 - 倒数第二少的颜色;
      #               以此类推
      #
      # Returns 一种配色方案
      def gen_palette( accent_seed: nil, fewest_index: 0 )
        accent_color = accent_seed || most_possible_accent_color( fewest_index )
        light, dark  = most_possible_around_colors( accent_color )
        text_color   = readable_textcolor bg: accent_color, accent: main_color
        {
          primary:        accent_color,
          :'pri-light' => light,
          :'pri-dark'  => dark,
          back:           @main_color,
          text:           text_color
        }
      end

      def most_possible_accent_color( fewest_index=0, &block )

        color = if raw_colors.size > fewest_index + 1
          # 除去最多的一种颜色
          # 因为最多的颜色是作为 back
          raw_colors.reverse[0..-2].compact.sort_by do |c|
            hue_simi   = hue_similarity(c, main_color)
            simi       = hue_simi > 60 ? -0.5*hue_simi + 120 : 1.5*hue_simi
            l,a,b      = *rgb2lab(c)
            sat        = c.to_hsl.s
            # 按和主要颜色的差异系数由小到大排
            # 饱和度越高、亮度越低的越有可能成为主色
            # simi: 0-90; l: 0-100; sat:  0-1
            simi * 2 + sat * 10 - l * 7.01
          end.reverse[fewest_index]
        elsif raw_colors.size > 0
          raw_colors.first
        else
          Color::RGB.from_html '#000000'
        end

        if max_pri_brightness
          color.to_hsl.tap do |c|
            c.l = max_pri_brightness if c.l > max_pri_brightness
          end.to_rgb
        else
          color
        end
      end

      def most_possible_around_colors( accent_color )
        sub_color1 = nil
        sub_color2 = nil

        if raw_colors.size > 4
          raw_colors[1..-1].each do |c|
            if hue_similarity(c, accent_color ) < 30
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
        end

        sub_color1 ||= accent_color.to_hsl.tap {|c| lighten!(c, 0.2) }.to_rgb
        sub_color2 ||= accent_color.to_hsl.tap {|c| darken!(c, 0.2) }.to_rgb
        [sub_color1, sub_color2]
      end
          
  end

end
