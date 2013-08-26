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

ARGV[5..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def perform_continental_base_noise_addition(cb_w,cb_h,continental_base,target_w,target_h,seed)
	log "adding noise, seed #{seed}"

	# scale
	log "scaling..."
	map = rescale(continental_base,cb_w,cb_h,target_w,target_h)

	# antialias
	log "antialiasing..."
	antialias_level = ([target_w.to_f/cb_w.to_f,target_h.to_f/cb_h.to_f].max).ceil
	antialias!(map,target_w,target_h,antialias_level)

	# noise addition
	log "adding noise..."
	map = add_noise(target_w,target_h,map,seed)	

	if $SAVING
		save_marshal_file($OUTPUT,map)
	end

	if $SHOW
		colors = Colors.new
		draw_code = Proc.new do |x,y|
			color = colors.get(map[y][x])
			color = shadow_color(map,color,x,y)
		end

		mf = MapFrame.new("Continental base with noise, seed #{seed}", target_w, target_h, draw_code)
		mf.launch
	end
end

continental_base = load_marshal_file($INPUT)
width = map_width(continental_base)
height = map_height(continental_base)
perform_continental_base_noise_addition(width,height,continental_base,$TARGET_W,$TARGET_H,$SEED)

puts "done."