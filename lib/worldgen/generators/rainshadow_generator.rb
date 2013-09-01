require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/rain'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "rainshadow_generator <elev> <wind> <output>"

show_usage if ARGV.count<3
$INPUT_ELEV  = ARGV[0]
$INPUT_WIND  = ARGV[1]
$OUTPUT = ARGV[2]

ARGV[3..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def generate(w,h,elev_map,wind_map)
	rainshadow_map = calc_rain_shadow(w,h,elev_map,wind_map)

	save_marshal_file($OUTPUT,rainshadow_map) if $SAVING
	
	if $SHOW
		colors = RainShadowColors.new
		draw = Proc.new do |x,y|
			if elev_map[y][x] < 0
				Color.new(0,0,0)
			else
				colors.get(rainshadow_map[y][x])
			end
		end
	end

	mf = MapFrame.new("Rainshadow map", w, h, draw)
	mf.launch
end

elev_map = load_marshal_file($INPUT_ELEV)
wind_map = load_marshal_file($INPUT_WIND)
w = map_width(elev_map)
h = map_height(elev_map)
generate(w,h,elev_map,wind_map) 

puts "done."