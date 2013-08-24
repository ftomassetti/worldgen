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
	water_map = particles_erosion(w,h,map,1000000)

	n_land_with_water = 0
	n_land_without_water = 0
	each_in_map(w,h,water_map) do |x,y,v|
		if map[y][x]>=0.0
			if v>0
				n_land_with_water+=1
			else
				n_land_without_water+=1
			end
		end
	end
	puts "Land with water: #{n_land_with_water}"
	puts "Land without water: #{n_land_without_water}"

	water_power_map = derive_map_from_map(water_map,w,h) do |x,y,v|
		Math.log(v)
	end

	water_colors = BwColors.new
	max_water = 0.0
	each_in_map(w,h,water_power_map) { |x,y,v| max_water = v if v>max_water }
	draw_water = Proc.new do |x,y|
		if map[y][x]<0
			Color.new 0,0,255
		else
			p = (water_power_map[y][x]/max_water)
			p=0 if p<0
			p=1 if p>1
			color = water_colors.get(p*4000.0)
		end
	end
	
	mf = MapFrame.new("Erosion: watermap, seed #{seed}", w, h, draw_water)
	mf.launch

	mf = MapFrame.new("Erosion: 50 steps, seed #{seed}", w, h, draw_code)
	mf.launch

	# particles_erosion(w,h,map,500000)
	
	# mf = MapFrame.new("Erosion: 100 steps, seed #{seed}", w, h, draw_code)
	# mf.launch

	# particles_erosion(w,h,map,1000000)
	
	# mf = MapFrame.new("Erosion: 200 steps, seed #{seed}", w, h, draw_code)
	# mf.launch
end

(6..6).each do |seed| 
	w = 1200
	h = 800
	path = "examples/continental_base_#{w}x#{h}_#{seed}_with_noise.contbase"
	map = load_marshal_file(path)
	perform_erosion(w,h,map,seed) 
end

puts "done."