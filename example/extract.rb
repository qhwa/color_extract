$:.unshift File.expand_path( '../../lib', __FILE__ )
require 'color_extract'

file = ARGV[0]
if file
  puts "File: #{file}"
  ColorExtract::Analytics.new( file ).valuable_colors.each do |per, color|
    print "  - %#.2f%% %s %s" % [per*100, color.html, color.css_hsl]
    print "\n"
  end

  puts "palette:"
  ColorExtract::Palette.new( file ).palette.each do |name, color|
    next unless color
    print "  - %s : %s %s" % [ name.to_s.ljust(6), color.html, color.css_hsl ]
    print "\n"
  end
end
