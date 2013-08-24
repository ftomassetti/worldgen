require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/rain'

include WorldGen

def generate(w,h,elev_map,wind_map,seed)
	rainshadow_map = calc_rain_shadow(w,h,elev_map,wind_map)
	colors = RainShadowColors.new
	draw = Proc.new do |x,y|
		if elev_map[y][x] < 0
			Color.new(0,0,0)
		else
			colors.get(rainshadow_map[y][x])
		end
	end

	outpath = "examples/rainshadowmap_#{w}x#{h}_#{seed}.rainshadow"
	save_marshal_file(outpath,rainshadow_map)
	
	mf = MapFrame.new("Rainshadow map, seed #{seed}", w, h, draw)
	mf.launch
end

(6..6).each do |seed| 
	w = 1200
	h = 800
	elev_map = load_marshal_file("examples/continental_base_#{w}x#{h}_#{seed}_with_noise.contbase")
	wind_map = load_marshal_file("examples/windmap_#{w}x#{h}_#{seed}.wind")
	generate(w,h,elev_map,wind_map,seed) 
end

puts "done."