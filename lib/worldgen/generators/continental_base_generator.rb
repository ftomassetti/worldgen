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
$NOISE_POWER = 1.0
$SEANESS = 0.35

ARGV[3..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'noise'
		$NOISE_POWER = value.to_f
	else
		error "Unknown param: #{name}"
	end
end

def perform_continental_base_calculation(plates,seed)
	w = plates.width
	h = plates.height
	continental_base = calculate_continental_base(plates,seed,$SEANESS,$OUTPUT,$NOISE_POWER)	

	continental_base.save if $SAVING

	if $SHOW
		colors = Colors.new
		draw_code = Proc.new do |x,y|
			colors.get(continental_base.get(x,y))
		end

		mf = MapFrame.new("Continental base, seed #{seed}", w, h, draw_code)
		mf.launch
	end
end

plates = Map.load($INPUT,:short)

perform_continental_base_calculation(plates,$SEED) 

puts "done."