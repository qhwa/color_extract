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
    def palette( accent_seed: nil )
      palettes( count: 1, accent_seed: accent_seed ).first
    end

    def palettes( opts={} )
      @raw_colors ||= @analytics.valuable_colors.map {|per, c| c }
      @palettes   ||= gen_palettes( opts )
    end

    private

      # 目前采用最简单
      def gen_palettes( count: 1, accent_seed: nil, max_pri_brightness: 1 )
        count               = 1 if accent_seed
        @max_pri_brightness = max_pri_brightness
        @main_color         = most_possible_main_color
        @accent_colors      = []

        palettes = count.times.map do |i|
          gen_palette( accent_seed: accent_seed, fewest_index: i )
        end.compact.sort_by do |pal|
          pal[:primary].to_hsl.h
        end

        if palettes.size < count

          if palettes.empty?
            return preset_palettes( count: count )
          end

          last_primary_color = palettes.last[:primary].to_hsl
          main_color         = palettes.last[:back].to_hsl
          puts last_primary_color.html
          (count - palettes.size ).times do |i|
            if i.even?
              color = last_primary_color.dup.tap do |c|
                h   = c.h
                h  += ((i+1)/2.0).ceil / 10.0
                h  += 1 if h < 0 
                c.h = h
                c.l = 0.33
              end.to_rgb
            else
              color = main_color.dup.tap do |c|
                h   = c.h
                h  -= ((i+1)/2.0).ceil / 10.0
                h  += 1 if h < 0 
                c.h = h
                c.l = 0.33
              end.to_rgb
            end
            next if already_have_similar_accent_color?( color )
            palettes << gen_palette( accent_seed: color )
          end
        end

        palettes.compact
      end

      def preset_palettes( count: 1 )
        0.upto(count).map do |i|
          accent = Color::HSL.from_fraction( i*(1.0 /(count+1)), 0.95, 0.4 )
          main   = Color::RGB.from_html( '#ffffff' )
          { 
            :primary      => accent.to_rgb,
            :back         => main,
            :"pri-dark"   => darken( accent, 0.2 ).to_rgb,
            :"pri-light"  => lighten( accent, 0.2 ).to_rgb,
            :"text"       => readable_textcolor( bg: accent.to_rgb, accent: main.to_rgb )
          }
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
        if !accent_color || already_have_similar_accent_color?( accent_color )
          return nil
        else
          @accent_colors << accent_color
        end

        if accent_color
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
        end

        if max_pri_brightness && color
          color.to_hsl.tap do |c|
            c.l = max_pri_brightness if c.l > max_pri_brightness
          end.to_rgb
        else
          color
        end
      end

      def already_have_similar_accent_color?( color )
        @accent_colors.any? do |c|
          similarity( c, color, ignore_lightness: false ) < 20
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
