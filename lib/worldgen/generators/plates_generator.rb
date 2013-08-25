# Program to perform initial generation of plaques

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'

include WorldGen

$SAVING = true
$SHOW   = true
$WIDTH  = 300
$HEIGHT = 300
$N_HOT_POINTS = 35
$DISTURB_STRENGTH = 12

$USAGE = "plates_generator <seed> <output>"

def show_usage
	puts $USAGE
	exit
end

def error(msg)
	puts msg
	exit
end

show_usage if ARGV.count<2 
$SEED   = ARGV[0].to_i
$OUTPUT = ARGV[1]

ARGV[2..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'w'
		$WIDTH = value.to_i
	when 'h'
		$HEIGHT = value.to_i
	when 'hps'
		$N_HOT_POINTS = value.to_i
	else
		error "Unknown param: #{name}"
	end
end

def perform_generation(width,height,n_hot_points,disturb_strength,seed)
	plates = generate_plaques(width,height,n_hot_points,disturb_strength,seed)

	if $SAVING
		save_marshal_file($OUTPUT, plates)
	end

	if $SHOW
		n_color_intervals = (cube_root(n_hot_points).floor) +1
		colors = GraduatedColors.new n_color_intervals
		draw_code = Proc.new do |x,y|
			plaque_index = plates[y][x]
			color = colors.get plaque_index
			color
		end
		mf = MapFrame.new("Plates seed #{seed}", width, height, draw_code)
		mf.launch
	end
end

perform_generation $WIDTH, $HEIGHT, $N_HOT_POINTS, $DISTURB_STRENGTH, $SEED

puts "done."