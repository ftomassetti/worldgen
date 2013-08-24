require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/erosion'

include WorldGen

def perform_erosion(w,h,map,seed)
	w = 1200
	h = 800
	#map = rescale(map,1200,800,w,h)
	colors = Colors.new
	draw_code = Proc.new do |x,y|
		color = colors.get(map[y][x])
		color = shadow_color(map,color,x,y)
	end

	mf = MapFrame.new("Erosion: initial, seed #{seed}", w, h, draw_code)
	mf.launch

	#erosion(w,h,map,50)
	particles_erosion(w,h,map,5000000)
	
	mf = MapFrame.new("Erosion: 50 steps, seed #{seed}", w, h, draw_code)
	mf.launch

	# particles_erosion(w,h,map,500000)
	
	# mf = MapFrame.new("Erosion: 100 steps, seed #{seed}", w, h, draw_code)
	# mf.launch

	# particles_erosion(w,h,map,1000000)
	
	# mf = MapFrame.new("Erosion: 200 steps, seed #{seed}", w, h, draw_code)
	# mf.launch
end

(1..1).each do |seed| 
	w = 1200
	h = 800
	path = "examples/continental_base_#{w}x#{h}_#{seed}_with_noise.contbase"
	map = load_marshal_file(path)
	perform_erosion(w,h,map,seed) 
end

puts "done."