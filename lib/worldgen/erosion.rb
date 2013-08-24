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
	n_cycles.times { |i|puts "Erosion #{i}";erosion_cycle(w,h,map,sediment_map,water_map) }
	[water_map,sediment_map]
end

$rain_amount = 100
$rain_solubility = 0.01
$solubility = 0.00001
$evaporation = 0.99
$capacity = 0.02

class Particle
	attr_reader :mass
	attr_reader :pos
	attr_reader :prov_alt
	attr_reader :prov_pos

	def initialize(pos)
		@pos = pos
		@speed = 1.0
		@mass  = 0.5
		@prov_alt = nil
		@prov_pos = nil
	end

	def move(w,h,map,erodibility_map)
		my_alt = map[@pos[1]][@pos[0]]
		arounds = []
		each_around(@pos) do |ax,ay|
			if ax>=0 and ay>=0 and ax<w and ay<h
				alt = map[ay][ax]
				arounds << [ax,ay,alt]
			end
		end
		arounds = arounds.select {|a| a[2]<my_alt}
		dest_alt = nil
		if arounds.count > 0
			arounds = arounds.sort_by{ |a| a[2] }
			dest = [arounds.first[0],arounds.first[1]]
			dest_alt = arounds.first[2]
			diff_alt = my_alt-arounds.first[2]
			instantaneous_speed = Math.log(diff_alt,10)
			@speed = (@speed*4+instantaneous_speed*1)/5.0
			speed_th = 0.5
			if @speed > speed_th
				erosion = (@speed-speed_th)*0.3*(0.5+erodibility_map[dest[1]][dest[0]]/2.0)
				map[dest[1]][dest[0]] -= erosion
				each_around(dest) do |ax,ay| 
					if [ax,ay]!=@pos and my_alt>map[ay][ax]
						map[ay][ax] -= (erosion/2.0) 
					end
				end
				#puts "removing #{erosion} at #{dest[1]},#{dest[0]}"
				@mass += erosion
			end
			@prov_alt = my_alt
			@prov_pos = @pos
			@pos = dest
		end
		dest_alt and dest_alt>=0.0 
	end

	def update_water_map(water_map)
		water_map[@pos[1]][@pos[0]] += @mass
	end
end

def rainshadowed(pos,rainshadow_map,rs)
	x,y=pos
	rainshadow = rainshadow_map[y][x]
	rainshadow>0.0 and rs.rand<=rainshadow
end

def particles_erosion(w,h,map,erodibility_map,rainshadow_map,rs,n_particles)
	rainshadow_map[700][1000]

	r = Rectangle.new w,h
	water_map = build_fixed_map(w,h)
	n_particles.times do |i|
		puts "particles #{i}" if i%10000==0
		# random starting point
		pos = nil
		while not pos or map[pos[1]][pos[0]]<0.0 or rainshadowed(pos,rainshadow_map,rs)
			pos = r.random_point(rs)
		end
		particle = Particle.new pos
		while particle.move(w,h,map,erodibility_map)
			particle.update_water_map(water_map)
			# if speed high remove
		end
		x,y = particle.pos
		#alt = map[y][x]
		deposit = particle.mass
		if particle.prov_alt
			max_deposit = particle.prov_alt-map[y][x]
			deposit = [deposit,max_deposit].min
		end
		map[y][x]+=deposit
		each_around(particle.pos) { |ax,ay| (map[ay][ax] += (deposit/2.0)) if [ax,ay]!=particle.prov_pos } 
		#puts "deposit #{deposit} at #{x},#{y}"
		# deposit at last position
	end
	water_map
end

def erosion_cycle(w,h,map,sediment_map,water_map)
	difference_map = build_fixed_map(w,h)
	water_map_diff = build_fixed_map(w,h) 
	sediment_map_diff = build_fixed_map(w,h) 
	strength_entering_map = build_fixed_map(w,h)

	r = Rectangle.new w,h

	# 1. add rain_amount to each cell of the water_map
	r.each {|x,y| water_map[y][x] += $rain_amount }

	#print_map(w,h,water_map,"STEP 1 water map after rain")

	# 2. rain erosion
	r.each do |x,y| 
		if map[y][x]>0.0 # ocean is not eroded by rain
			soluted_terrain = $rain_solubility*$rain_amount
			difference_map[y][x] -= soluted_terrain
			sediment_map[y][x]   += soluted_terrain
		end
	end

	#print_map(w,h,sediment_map,"STEP 1 Sediment map")

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
	#		puts "STEP 3, [#{x},#{y}] #{alt}m (#{alt_with_water}m ww) moving toward [#{o_x},#{o_y}] (#{o_alt}m, #{o_alt_with_water}m ww)"
			if o_alt_with_water+my_water<=alt
				moved_water = my_water
			else
				diff = (alt_with_water-o_alt_with_water)
				moved_water = diff/2.0	
			end

			water_map_diff[y][x] -= moved_water
			water_map_diff[o_y][o_x] += moved_water
			p = moved_water/my_water
			sediment_map_diff[o_y][o_x] += p*sediment_map[y][x]
			sediment_map_diff[y][x]     -= p*sediment_map[y][x]					
	#		puts "\tmoving part of the water and sediment #{moved_water} water, #{p*sediment_map[y][x]} sediment"
			strength_entering_map[o_y][o_x] += (alt_with_water-o_alt_with_water)*moved_water
		else
	#		puts "STEP 3, [#{x},#{y}] #{alt}m, lowest point -> no movement"
		end
	end
#	end

	#print_map(w,h,strength_entering_map,"STEP 3 strength_entering_map")	

	r.each do |x,y| 
		water_map[y][x] += water_map_diff[y][x]
		sediment_map[y][x] += sediment_map_diff[y][x]
	end

	# 3b. flux erosion
	r.each do |x,y| 
		#if map[y][x]>0.0 # ocean is not eroded by rain
		soluted_terrain = $solubility*strength_entering_map[y][x]
		#puts "Soluted terrain by flux #{x},#{y} #{soluted_terrain}"
		difference_map[y][x] -= soluted_terrain
		sediment_map[y][x]   += soluted_terrain
		#end
	end

	#print_map(w,h,water_map,"STEP 4 water map before evaporation")	

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
		sediment_in_the_water = water_map[y][x]*$capacity*(1+strength_entering_map[y][x]**0.1)
		sediment_to_deposit = sediment_map[y][x]-sediment_in_the_water
		#puts "STEP 4, [#{x},#{y}] sediment #{sediment_map[y][x]}, remaining in the water #{sediment_in_the_water}, to deposit #{sediment_to_deposit}"

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