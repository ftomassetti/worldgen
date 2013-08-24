require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/temperature'

include WorldGen

def generate(w,h,elev_map,seed)
	temperature_map = gen_temperature_map(w,h,elev_map,seed)
	colors = TemperatureColors.new
	draw = Proc.new do |x,y|
		if elev_map[y][x] < 0
			Color.new(0,0,0)
		else
			colors.get temperature_map[y][x]
		end
	end

	outpath = "examples/temperaturemap_#{w}x#{h}_#{seed}.temp"
	save_marshal_file(outpath,temperature_map)
	
	mf = MapFrame.new("Temperature map, seed #{seed}", w, h, draw)
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