# Program to generate from polished plaques basic continental altitude and
# plaques border reliefs or depressions

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/console'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "continental_base_generator <input> <output> <seed>"

show_usage if ARGV.count<3
$INPUT  = ARGV[0]
$OUTPUT = ARGV[1]
$SEED   = ARGV[2].to_i
$SEANESS = 0.35

ARGV[3..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def perform_continental_base_calculation(w,h,plates,seed)
	continental_base = calculate_continental_base(w,h,plates,seed,$SEANESS)	

	save_marshal_file($OUTPUT,continental_base) if $SAVING

	if $SHOW
		colors = Colors.new
		draw_code = Proc.new do |x,y|
			colors.get(continental_base[y][x])
		end

		mf = MapFrame.new("Continental base, seed #{seed}", w, h, draw_code)
		mf.launch
	end
end

plates = load_marshal_file($INPUT)
width = map_width(plates)
height = map_height(plates)

perform_continental_base_calculation(width,height,plates,$SEED) 

puts "done."