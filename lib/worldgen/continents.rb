require 'worldgen/plates'
require 'worldgen/map'
require 'worldgen/combined_perlin'
require 'worldgen/noises'

module WorldGen

def add_noise(w,h,map,seed)
	cp = CombinedSimplex.new 3,seed,4,256
	derive_map_from_map(map,w,h,'adding noise') do |x,y,orig_val|
		xp = 4.0*(x.to_f/w.to_f)
		yp = 4.0*(y.to_f/h.to_f)
		new_val = (cp.get xp,yp)*1000+300
		orig_val+new_val
	end
end

def calculate_continental_base(w,h,plaques,seed,seaness)
	process_random = Random.new seed
	log "Calculating border plaques"
	border_plaques = plaques_at_border_of_the_map(w,h,plaques)

	n_plaques = number_of_plaques(w,h,plaques)

	platform_rand = Random.new(process_random.rand)	
	border_rand   = Random.new(process_random.rand)
	border_dists_rand = Random.new(process_random.rand)

	platform_elevations = Hash.new do |hash, plaque_i|
		hash[plaque_i] = height_platform(border_plaques,platform_rand,plaque_i,seaness)
	end

	border_dists = Hash.new do |hash, plaque_i|
		hash[plaque_i] = border_dists_rand.rand(15)+border_dists_rand.rand(15)
	end

	plates_sizes = Hash.new do |hash,plate_i|
		hash[plate_i] = points_of_plaque(w,h,plaques,plate_i).count
	end

	border_elevations = Hash.new do |hash, key| 
		hash[key] = elevation_of_borders(plates_sizes,key[0],key[1],border_rand,platform_elevations)
	end

	plaques_borders_map(w,h,plaques,platform_elevations,border_elevations,border_dists,process_random.rand)
end

def height_platform(border_plaques,random,plaque_i,seaness)
	marine = ((border_plaques.include?(plaque_i)) || (rs=random.rand;puts "Rs: #{rs} #{seaness}";rs<seaness))
	#puts "\tmarine:#{marine} border:#{(border_plaques.include?(plaque_i))}"
	if marine
		elev = -10000+random.rand(500)+random.rand(500)
	else
		elev = 200+random.rand(200)+random.rand(200)
	end
	log "Height of platform: #{plaque_i} = #{elev}m"
	elev
end

def elevation_of_borders(plates_sizes,a,b,random,platform_elevations)
	size_a = plates_sizes[a]
	size_b = plates_sizes[b]
	size_factor = (Math.log(size_a))/8.0*(Math.log(size_b))/8.0
	raise "should not be negative" if size_factor<0.0

	pos_a = platform_elevations[a]>0
	pos_b = platform_elevations[b]>0

	if pos_a
		asc = true
	elsif random.rand < 0.5
		asc = false
	else
		asc = true		
	end
	if asc
		# ascending
		if pos_a
			v = random.rand(5000)
		else
			v = random.rand(5000)+random.rand(5000)+random.rand(5000)
		end
	else
		# descending
		v = -(random.rand(1500))-(random.rand(1500))
	end
	alt_a = platform_elevations[a]
	alt_b = platform_elevations[b]
	v *= size_factor
	v *= 1
	log "Border between #{a} (#{alt_a}m) and #{b} (#{alt_b}m) = #{v}m"
	v
end

#MAX_DIST = 20

def plaques_borders_map(w,h,plaques,platform_elevations,border_elevations,border_dists,seed)	

	#noise_source = Perlin::Noise.new(2, :seed => seed )
	noise_source = simplex_noise((seed*2356).to_i)

	derive_map_from_map(plaques,w,h,"calculating plaques borders") do |x,y,plaque_i|
		v=platform_elevations[plaque_i]
		other = nil
		max_dist = border_dists[plaque_i] # it is on per plaque base... let's see if it has sense
		(1..max_dist).each do |d|
			unless other 
				attenuation = 1+max_dist-d
				other = plaques[y][x-d] if x>d and plaques[y][x]!=plaques[y][x-d]
				other = plaques[y][x+d] if x+d<w and plaques[y][x]!=plaques[y][x+d]
				other = plaques[y-d][x] if y>d and plaques[y][x]!=plaques[y-d][x]
				other = plaques[y+d][x] if y+d<h and plaques[y][x]!=plaques[y+d][x]
			
				if other
					delta = border_elevations[[plaque_i,other]]/attenuation
					
					# add some noise
					px = 16.0*(x.to_f/w.to_f)
					py = 16.0*(y.to_f/h.to_f)
					noise = (noise_source.noise(px,py)+1.0)/2.0
					delta *= (0.5+noise/2.0)
					#puts "Delta #{delta}, d=#{d}, border=#{border_elevations[[plaque_i,other]]}"

					v = delta+platform_elevations[plaque_i]
				end
			end
		end
		v
	end
end

end