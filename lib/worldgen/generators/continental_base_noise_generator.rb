# Program to add noise to the continental base

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/console'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "continental_base_noise_generator <input> <output> <seed> <target_w> <target_h>"

show_usage if ARGV.count<3
$INPUT  = ARGV[0]
$OUTPUT = ARGV[1]
$SEED   = ARGV[2].to_i
$TARGET_W = ARGV[3].to_i
$TARGET_H = ARGV[4].to_i
$NOISE_POWER = 1.0

ARGV[5..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'noise'
		$NOISE_POWER = value.to_f
	else
		error "Unknown param: #{name}"
	end	
end

def perform_continental_base_noise_addition(continental_base,target_w,target_h,seed)
	cb_w = continental_base.width
	cb_h = continental_base.height
	log "adding noise, seed #{seed}"

	# scale
	log "scaling..."
	map = continental_base.rescale($OUTPUT,target_w,target_h)

	# antialias
	log "antialiasing..."
	antialias_level = ([target_w.to_f/cb_w.to_f,target_h.to_f/cb_h.to_f].max).ceil
	map.antialias!(antialias_level)

	# noise addition
	log "adding noise..."
	add_noise(map,seed,$NOISE_POWER)	

	map.save if $SAVING

	if $SHOW
		colors = Colors.new
		draw_code = Proc.new do |x,y|
			color = colors.get(map.get(x,y))
			#color = shadow_color(map,color,x,y)
		end

		mf = MapFrame.new("Continental base with noise, seed #{seed}", target_w, target_h, draw_code)
		mf.launch
	end
end

continental_base = Map.load($INPUT,:float)
perform_continental_base_noise_addition(continental_base,$TARGET_W,$TARGET_H,$SEED)

puts "done."