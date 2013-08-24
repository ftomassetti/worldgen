require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/wind'

include WorldGen

def generate(w,h,elev_map,seed)
	wind_map = gen_wind_map(w,h,elev_map,seed)
	colors = RadiantColors.new
	draw_wind = Proc.new do |x,y|
		colors.get wind_map[y][x]
	end

	outpath = "examples/windmap_#{w}x#{h}_#{seed}.wind"
	save_marshal_file(outpath,wind_map)
	
	mf = MapFrame.new("Windmap, seed #{seed}", w, h, draw_wind)
	mf.launch
end

(6..6).each do |seed| 
	w = 1200
	h = 800
	path = "examples/continental_base_#{w}x#{h}_#{seed}_with_noise.contbase"
	map = load_marshal_file(path)
	generate(w,h,map,seed) 
end

puts "done."