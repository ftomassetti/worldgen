require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/biomass'

include WorldGen

def count_and_print_map(w,h,map,name,&op)
	cm = Hash.new {|hash,key| hash[key] = 0}
	each_in_map(w,h,map) do |x,y,v|
		type = op.call(x,y,v)
		cm[type]+=1
	end
	puts "= #{name} ="
	cm.each do |k,v|
		puts "#{k} = #{v}"
	end
end

def humidity(x,y,v,water_map,elevation_map)
	if elevation_map[y][x]>=0
		sum = Math.log(1.0+v)*1.0
		surroundings([x,y],2) do |ax,ay|
			if elevation_map[ax,ay]<0
				sum+=9
			elsif r.include? [ax,ay]
				sum+=0.5*Math.log(1.0+water_map[ay][ax])
			else
				sum+=9
			end
		end
		sum
	else
		-1.0
	end
end

def perform(w,h,elevation_map,rainshadow_map,temperature_map,water_map,seed)
	log "Starting biomass calc"

	elevation_type_map = Hash.new do |hash,key|
		x,y = key
		v = elevation_map[y][x]
		hash[key]=elevation_type(v)
	end
	temperature_type_map = Hash.new do |hash,key|
		x,y = key
		v = temperature_map[y][x]
		hash[key]=temperature_type(v)
	end
	humidity_type_map = Hash.new do |hash,key|
		x,y = key
		v = water_map[y][x]
		hash[key]=humidity_type(humidity(x,y,v,water_map,elevation_map))
	end

	biome_cm = Hash.new {|h,k| h[k]=0}
	biome_type_cm = Hash.new {|h,k| h[k]=0}
	r = Rectangle.new w,h
	biome_map = build_map(w,h, 'biome map') do |x,y|
		#puts "biome #{y}" if x==0 and y%10==0
		p = [x,y]
		et = elevation_type_map[p]
		tt = temperature_type_map[p]
		ht = humidity_type_map[p]
		mix = [et,tt,ht]
		biome_cm[mix] += 1
		bt = biome_type(et,tt,ht)
		biome_type_cm[bt] += 1
		bt
	end	
	biome_cm.each do |k,v|
		et,tt,ht = k
		puts "#{k} = #{v} (type: #{biome_type(et,tt,ht)})"
	end
	biome_type_cm.each do |k,v|
		puts "#{k} = #{v}"
	end

	# count_and_print_map(w,h,elevation_map,'Elevation') {|x,y,v| elevation_type(v)}
	# count_and_print_map(w,h,temperature_map,'Temperature') {|x,y,v| temperature_type(v)}
	# r = Rectangle.new w,h
	# count_and_print_map(w,h,water_map,'Water') do |x,y,v| 
	# 	humidity_type(humidity(x,y,v,water_map,elevation_map))
	# end

	# biomass_map = calc_biomass_map

	colors = BiomeColors.new
	draw = Proc.new do |x,y|
		colors.get(biome_map[y][x])
	end

	mf = MapFrame.new("Biome, seed #{seed}", w, h, draw)
	mf.launch
end

(6..6).each do |seed| 
	w = 1200
	h = 800
	#data = {:erodibility=>erodibility_map, :water_map =>water_map, :elevation => map }
	data = load_marshal_file("examples/world_after_erosion_#{w}x#{h}_#{seed}.world")
	elev_map = data[:elevation]
	water_map = data[:water_map]
	rainshadow_map = load_marshal_file("examples/rainshadowmap_#{w}x#{h}_#{seed}.rainshadow")
	temperature_map = load_marshal_file("examples/temperaturemap_#{w}x#{h}_#{seed}.temp")
	perform(w,h,elev_map,rainshadow_map,temperature_map,water_map,seed) 
end

puts "done."