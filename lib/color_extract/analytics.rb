require 'colorscore'

module ColorExtract

  MAX_VISIBLE_COLORS = 128

  class Analytics

    include ColorUtil

    def initialize( img )
      @img = img
    end

    def valuable_colors
      @colors ||= calc_valuable_colors
    end

    private
      
      def calc_valuable_colors
        @colors = @raw_colors = visible_colors

        # 黑白灰是不具有色相的颜色，可以和任何色相的颜色搭配
        # 所以不是我们关心的颜色
        remove_gray_colors

        # 去掉灰色之后重新计算一下百分比，这样后期就不会有
        # 太多比例特别少的颜色，防止色彩丢失过多
        update_percents

        # 视觉上相近的颜色都合并成一种进行统计
        # 这样得到的颜色比例会更加精确
        merge_similar_colors

        # 数量太少的颜色很有可能是主色的过渡
        # 可以去掉和主色同色系的低比例色彩
        remove_few_colors

        return @colors
      end

      def visible_colors
        Colorscore::Histogram.new( @img, MAX_VISIBLE_COLORS).scores
      end
  
      def remove_gray_colors
        @colors.reject! do |per, color|
          hsl = color.to_hsl
          # 灰色系颜色
          l, a, b = *rgb2lab(color.to_rgb)
          hsl.s < 0.1 or
            # 接近白色
            l > 83 or
            # 接近黑色
            l < 25
        end
      end

      def update_percents
        total = @raw_colors.reduce(0) {|sum, info| sum + info[0]}
        @colors.each do |info|
          per, c = *info
          info[0] = per / total
        end
      end

      # TODO: 重构这个函数
      # 这里应该可以逻辑更加简单一些的
      def merge_similar_colors

        @colors.each do |info|
          per, c = *info
          info[1] = pure( dither( c ), s:nil, l:nil )
        end

        auto_link_colors!

        new_colors = {}
        @colors.each do |per, color|
          link_to = parent_color(color)
          if link_to
            new_colors[link_to] ||= 0
            new_colors[link_to] += per
          else
            new_colors[color.html] = per
          end
        end

        @colors = new_colors.map do |color_html, per|
          [per, Color::RGB.from_html(color_html)]
        end
      end

      def auto_link_colors!
        @merge_link = {}
        colors      = @colors
        len         = colors.size - 1
        
        0.upto(len) do |i|
          per, color, lab = *colors[i]
          hsl = color.to_hsl

          (i+1).upto(len) do |j|
            per2, color2, lab2 = *colors[j]
            hsl2 = color2.to_hsl

            if should_merge?(color, color2)
              # 相近的颜色，合并到面积更大的那种颜色
              # 这里尝试过另外的策略，比如合并到更鲜艳
              # 的那种颜色，但是效果不是很好
              if per >= per2
                @merge_link[color.html]  = parent_color(color2)
              else
                @merge_link[color2.html] = parent_color(color)
              end
            end
          end
        end
      end

      def should_merge?( color1, color2 )
        hue_similarity( color1, color2 ) <= 20 && similarity( color1, color2 ) < 15
      end

      def parent_color color
        parent = @merge_link[color.html]
        if parent
          parent_color( Color::RGB.from_html(parent) )
        else
          color.html
        end
      end

      def remove_few_colors
        sorted_colors = @colors.sort_by {|per,c| -per}
        if sorted_colors.size > 5
          sorted_colors.reject! {|per, c| per < 0.0005 }
        end
        common_colors = sorted_colors
        little_colors = sorted_colors.select {|per, c| per < 0.05 }

        little_colors.select! do |per, c|
          common_colors.any? do |common_per, common_color|
            common_per > per && hue_similarity( c, common_color ) <= 10
          end
        end

        @colors = sorted_colors - little_colors
      end

  end

end

