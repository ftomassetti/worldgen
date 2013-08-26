require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/wind'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "windmap_generator <elev> <output> <seed>"

show_usage if ARGV.count<3
$INPUT_ELEV  = ARGV[0]
$OUTPUT = ARGV[1]
$SEED   = ARGV[2].to_i

ARGV[3..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def generate(w,h,elev_map,seed)
	wind_map = gen_wind_map(w,h,elev_map,seed)

	save_marshal_file($OUTPUT,wind_map) if $SAVING
	
	if $SHOW
		colors = RadiantColors.new
		draw_wind = Proc.new do |x,y|
			colors.get wind_map[y][x]
		end
		mf = MapFrame.new("Windmap, seed #{seed}", w, h, draw_wind)
		mf.launch
	end
end


map = load_marshal_file($INPUT_ELEV)
w = map_width(map)
h = map_height(map)

generate(w,h,map,$SEED) 

puts "done."