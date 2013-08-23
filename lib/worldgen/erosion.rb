require 'worldgen/geometry'

module WorldGen

def calc_initial_water_map(w,h,map)
	# the sea tiles have already water on them...
	build_map(w,h,) do |x,y|
		alt = map[y][x]
		if alt>=0.0
			0.0
		else
			-1.0*alt
		end
	end
end

def calc_initial_sediment_map(w,h,initial_water_map)
	# we have already sediment in the water, so it is in equilibrium
	build_map(w,h,) do |x,y|
		water = initial_water_map[y][x]
		water*$capacity
	end
end

def erosion(w,h,map,n_cycles)
	water_map = calc_initial_water_map(w,h,map)
	#sediment_map = build_fixed_map(w,h)
	sediment_map = calc_initial_sediment_map(w,h,water_map)
	n_cycles.times { erosion_cycle(w,h,map,sediment_map,water_map) }
	[water_map,sediment_map]
end

$rain_amount = 100
$solubility = 0.05
$evaporation = 0.99
$capacity = 0.02

def erosion_cycle(w,h,map,sediment_map,water_map)
	difference_map = build_fixed_map(w,h)
	water_map_diff = build_fixed_map(w,h) 
	sediment_map_diff = build_fixed_map(w,h) 

	r = Rectangle.new w,h

	# 1. add rain_amount to each cell of the water_map
	r.each {|x,y| water_map[y][x] += $rain_amount }

	print_map(w,h,water_map,"STEP 1 water map after rain")

	# 2. erosion (fixed amount for everyone) to difference and sediment
	r.each do |x,y| 
		if map[y][x]>0.0
			soluted_terrain = $solubility*water_map[y][x]
			difference_map[y][x] -= soluted_terrain
			sediment_map[y][x]   += soluted_terrain
		end
	end

	print_map(w,h,sediment_map,"STEP 1 Sediment map")

	# 3. movement
	r.each do |x,y|
		alt = map[y][x]
#		if alt>0 # if not is ocean or depression...
		my_water = water_map[y][x]
		raise "water should not be negative" if my_water<0
		alt_with_water = alt+my_water
		others = []
		each_around([x,y]) do |ax,ay|
			if r.include?([ax,ay])
				alt_a = map[ay][ax]
				alt_with_water_a = alt_a + water_map[ay][ax]
				others << [ax,ay,alt_a,alt_with_water_a]
			end
		end
		others = others.select {|o| o[3]<alt_with_water}
		if others.count>0
			others = others.sort_by do |o|
				o[3]*1000+o[2] # consider first altww then alt
			end
			o_x,o_y,o_alt,o_alt_with_water = others.first
			puts "STEP 3, [#{x},#{y}] #{alt}m (#{alt_with_water}m ww) moving toward [#{o_x},#{o_y}] (#{o_alt}m, #{o_alt_with_water}m ww)"
			if o_alt_with_water+my_water<=alt
				# move all
				water_map_diff[y][x] = 0
				water_map_diff[o_y][o_x] += my_water
				sediment_map_diff[o_y][o_x] += sediment_map[y][x]
				sediment_map_diff[y][x] -=  sediment_map[y][x]

				puts "\tmoving all the water and sediment #{my_water} water, #{sediment_map[y][x]} sediment"
			else
				diff = (alt_with_water-o_alt_with_water)
				moved = diff/2.0	
				water_map_diff[y][x] -= moved
				water_map_diff[o_y][o_x] += moved
				p = moved/my_water
				sediment_map_diff[o_y][o_x] += p*sediment_map[y][x]
				sediment_map_diff[y][x] -=     p*sediment_map[y][x]					

				puts "\tmoving part of the water and sediment #{moved} water, #{p*sediment_map[y][x]} sediment"
			end
		else
			puts "STEP 3, [#{x},#{y}] #{alt}m, lowest point -> no movement"
		end
	end
#	end

	r.each do |x,y| 
		water_map[y][x] += water_map_diff[y][x]
		sediment_map[y][x] += sediment_map_diff[y][x]
	end

	print_map(w,h,water_map,"STEP 4 water map before evaporation")	

	# 4. evaporation
	r.each do |x,y| 
		if map[y][x]>=0.0
			evaporable_water = water_map[y][x]
		else
			evaporable_water = water_map[y][x]+map[y][x]
		end
		evalporable_water = 0.0 if evaporable_water < 0.0
		water_map[y][x] -= evaporable_water*(1.0-$evaporation)
	end
	r.each do |x,y| 
		sediment_in_the_water = water_map[y][x]*$capacity
		sediment_to_deposit = sediment_map[y][x]-sediment_in_the_water
		puts "STEP 4, [#{x},#{y}] sediment #{sediment_map[y][x]}, remaining in the water #{sediment_in_the_water}, to deposit #{sediment_to_deposit}"

		if sediment_to_deposit>0
			sediment_map[y][x] -= sediment_to_deposit
			difference_map[y][x] += sediment_to_deposit
		end
	end

	#print_map(w,h,water_map,"STEP 4 water map after evaporation")

	# 5. apply diff
	r.each do |x,y| 
		map[y][x] += difference_map[y][x]

		#$total_difference_map[y][x] += $difference_map[y][x]
		#raise "not a number but #{map[y][x].class}" unless map[y][x].is_a? Float or alt.is_a? Fixnum
		#difference_map[y][x] = 0.0 
	end
	#print_map(w,h,map,"Final elev map")
	#print_map(w,h,sediment_map,"Final sediment map")
	#print_map(w,h,water_map,"Final water map")
end

end