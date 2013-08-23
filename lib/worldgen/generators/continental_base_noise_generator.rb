# Program to add noise to the continental base

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'

include WorldGen

def perform_continental_base_noise_addition(cb_w,cb_h,continental_base,target_w,target_h,seed)
	log "adding noise, seed #{seed}"

	# scale
	log "scaling..."
	map = rescale(continental_base,cb_w,cb_h,target_w,target_h)

	# antialias
	log "antialiasing..."
	antialias!(map,target_w,target_h,3)

	# noise addition
	log "adding noise..."
	add_noise!(target_w,target_h,map,seed)	

	colors = Colors.new
	draw_code = Proc.new do |x,y|
		color = colors.get(map[y][x])
		color = shadow_color(map,color,x,y)
	end

	outpath = "examples/continental_base_#{target_w}x#{target_h}_#{seed}_with_noise.contbase"
	save_marshal_file(outpath,map)

	mf = MapFrame.new("Continental base with noise, seed #{seed}", target_w, target_h, draw_code)
	mf.launch
end

(1..5).each do |seed| 
	log "Calculating continental base noise with seed #{seed}"	
	path = outpath = "examples/continental_base_#{seed}.contbase"
	continental_base = load_marshal_file(path)
	width  = 300
	height = 300
	perform_continental_base_noise_addition(width,height,continental_base,1200,800,seed)
end

puts "done."