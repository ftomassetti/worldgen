# Program to generate from polished plaques basic continental altitude and
# plaques border reliefs or depressions

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'

include WorldGen

def perform_continental_base_calculation(w,h,plaques,seed)
	continental_base = calculate_continental_base(w,h,plaques,seed)	

	colors = Colors.new
	draw_code = Proc.new do |x,y|
		colors.get(continental_base[y][x])
	end

	outpath = "examples/continental_base_#{seed}.contbase"
	save_marshal_file(outpath,continental_base)

	mf = MapFrame.new("Continental base, seed #{seed}", w, h, draw_code)
	mf.launch
end

(1..5).each do |seed| 
	log "Calculating continental base with seed #{seed}"
	width = 300
	height = 300
	n_hot_points = 35 
	path = "examples/plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}_polished.plaques"
	plaques = load_marshal_file(path)
	perform_continental_base_calculation(width,height,plaques,seed) 
end

puts "done."