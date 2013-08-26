# Program to polish plaques

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/visualizations/images'

include WorldGen


$USAGE = "image_saver <input>"

show_usage if ARGV.count<1
$INPUT  = ARGV[0]
$OUTPUT = ARGV[1]

def set_type(type)
	case type
	when 'geo'
		colors = Colors.new
		$draw_code = Proc.new do |x,y|
			color = colors.get($map[y][x])
			color = shadow_color($map,color,x,y)		
		end	
	else
		error "Unknown type: #{type}"
	end
end

ARGV[2..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'type'
		set_type(value)	
	else
		error "Unknown param: #{name}"
	end
end

$map = load_marshal_file($INPUT)
width = map_width($map)
height = map_height($map)
colors = Colors.new
save_image(width,height,$OUTPUT) do |x,y|
	puts "line #{y}" if x==0 and y%10==0
	color = colors.get($map[y][x])
	color = shadow_color($map,color,x,y)
end
puts "done."