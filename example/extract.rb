$:.unshift File.expand_path( '../../lib', __FILE__ )
require 'color_extract'

file = ARGV[0]
if file
  puts "File: #{file}"
  ColorExtract::Analytics.new( file ).valuable_colors.each do |per, color|
    print "  - #{color.html} "
    print( '%#.2f%%' % (per*100) )
    print "\n"
  end
end
