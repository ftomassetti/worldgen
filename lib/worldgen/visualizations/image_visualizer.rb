# Program to polish plaques

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'

include WorldGen


$USAGE = "image_visualizer <input>"

show_usage if ARGV.count<1
$INPUT  = ARGV[0]

grcolors = GraduatedColors.new n_plaques
$draw_code = Proc.new do |x,y|
	plate_index = plates[y][x]		
	grcolors.get plate_index
end

def set_type(type)
	case type
	when 'geo'
		colors = Colors.new
		$draw_code = Proc.new do |x,y|
			color = colors.get($map[y][x])
			color = shadow_color($map,color,x,y)		
			colors.get plate_index
		end	
	else
		error "Unknown type: #{type}"
	end
end

ARGV[1..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'type'
		set_type(value)	
	else
		error "Unknown param: #{name}"
	end
end

$map = load_marshal_file($INPUT)
width = map_width(plates)
height = map_height(plates)
n_plaques = number_of_plaques(width,height,plates)
mf = MapFrame.new("Polished plates", width, height, $draw_code)
mf.launch

puts "done."