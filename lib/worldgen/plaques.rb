require 'set'
require 'perlin_noise'
require 'worldgen/log'
require 'worldgen/geometry'
require 'worldgen/map'

module WorldGen

def number_of_plaques(w,h,plaques)
	max = -1
	each_in_map(w,h,plaques) do |x,y,plaque_index|
		max=plaque_index if plaque_index>max
	end
	max+1
end

def points_of_plaque(w,h,map,index)
	points = []
	Rectangle.new(w,h).each do |x,y|
		points << [x,y] if map[y][x]==index
	end
	points
end

def generate_plaques(width,height,n_hot_points,disturb_strength=25,seed)
	log "generate plaques started: dim=#{width}x#{height}, n_hot_points: #{n_hot_points}, seed: #{seed}"
	general_random = Random.new seed
	log "generating hot points"
	hot_points = gen_hot_points(width,height,n_hot_points,Random.new(general_random.seed))
	log "building distances map"
	distances_map = calc_hotpoints_distances_map(width,height,hot_points)
	log "disturbing distances map"
	disturb_distances_map(width,height,hot_points,distances_map,disturb_strength)
end

def gen_hot_points(w,h,n,random)
	area_from_which_pick = Rectangle.new( 
			(w*1.2).to_i,(h*1.2).to_i,
			-(w*0.2).to_i,(h*0.2).to_i)
	points = Set.new
	# technically it is possible to pick more than once the same point
	while points.count<n
		points << area_from_which_pick.random_point(random)
	end
	points.to_a
end

def calc_hotpoints_distances_map(w,h,hot_points)
	build_map(w,h) do |x,y|
		min_hpd = w*h
			sel_i = 0
			distances = []
			hot_points.each_with_index do |hp,i|
				hpd = distance([x,y],hp)
				distances << hpd				  
			end
		distances
	end
end

def disturb_distances_map(w,h,hot_points,distances_map,disturb_strength)
	noises = []
	hot_points.count.times { noises << Perlin::Noise.new(2, :interval => [w,h].max) }
	derive_map_from_map(distances_map,w,h,'inserting noise in distances map') do |x,y,distances|
		max = w*h
		sel_i = 0
		hot_points.each_with_index do |hp,i|
			noise_source = noises[i]
			px = 16.0*(x.to_f/w.to_f)
			py = 16.0*(y.to_f/h.to_f)
			tot = distances[i]+disturb_strength.to_f*noise_source[py,px]
			if tot<max
				sel_i = i
				max = tot
			end
		end
		sel_i
	end
end

def polish_plaques(w,h,plaques)
	log "Breaking plaques in blocks"
	break_plaques_in_blocks(w,h,plaques)
	log "Inglobing surrounded block"
	inglobe_surrounded_blocks(w,h,plaques)
end

def points_of_the_plaque(w,h,plaques,plaque_index)
	points = []
	each_in_map(w,h,plaques) do |x,y,val|
		points << [x,y] if val==plaque_index
	end
	points
end

def expand_block(w,h,map,block,p,val)
	return if block.include? p
	block << p
	r = Rectangle.new w,h
	each_around_limited(p) do |x,y|
		if r.include? [x,y]
			expand_block(w,h,map,block,[x,y],val) if map[y][x] == val
		end
	end
end

# Each plaque having not contiguos points is broken
def break_plaques_in_blocks(w,h,plaques)
	n_plaques = number_of_plaques(w,h,plaques)
	plaque_index=0
	while plaque_index<n_plaques
		log "breaking plaque #{plaque_index}"
		all_points = points_of_the_plaque(w,h,plaques,plaque_index)
		if all_points.count>0
			start_point = all_points[0]
			main_block = []
			expand_block(w,h,plaques,main_block,start_point,plaque_index)
			toremove = all_points.select {|p| not main_block.include? p}			
			if toremove.count>0
				log "plaque to be broken, #{toremove.count} points removed, #{main_block.count} kept"
				toremove.each {|p| x,y=p; plaques[y][x] = n_plaques}
				n_plaques += 1				
			end			
		end
		plaque_index += 1
	end
end

def get_first_neighbor_in_dir(w,h,plaques,start_point,dir)
	x,y = start_point
	my_plaque_index = plaques[y][x]

	while true
		next_x = x+dir[0]
		next_y = y+dir[1]
		next_point = [next_x,next_y]
		if Rectangle.new(w,h).include?(next_point)
			other_plaque_index = plaques[next_y][next_x]
			if other_plaque_index!=my_plaque_index
				return other_plaque_index
			else
				x = next_x
				y = next_y
			end
		else
			return nil
		end
	end
end

def get_first_neighbors_in_all_dirs(w,h,plaques,start_point)
	[get_first_neighbor_in_dir(w,h,plaques,start_point,[0,-1]),
		get_first_neighbor_in_dir(w,h,plaques,start_point,[1,0]),
		get_first_neighbor_in_dir(w,h,plaques,start_point,[0,1]),
		get_first_neighbor_in_dir(w,h,plaques,start_point,[-1,0])]
end

def container_inglobing_points(w,h,plaques,all_points)
	all_neighbors = []
	all_points.each do |p|
		new_neighbours = get_first_neighbors_in_all_dirs(w,h,plaques,p)
		new_neighbours.select {|v| v!=nil}.each {|v| all_neighbors << v unless all_neighbors.include?(v)}
		if all_neighbors.count>1
			return nil # more than one neighbour
		end
	end
	parent = all_neighbors[0]
	raise "Wrong! #{parent} (#{parent.class})" unless parent.is_a? Fixnum
	parent
end

# If a glob is totally contained by another block, the inner block become part of the outer block
def inglobe_surrounded_blocks(w,h,plaques)
	n_plaques = number_of_plaques(w,h,plaques)
	n_plaques.times do |plaque_index|
		log "considering for inglobation #{plaque_index}"
		all_points = points_of_the_plaque(w,h,plaques,plaque_index)		
		if all_points.count>0						
			parent = container_inglobing_points(w,h,plaques,all_points)
			if parent
				# ok, inglobe
				log "Going to inglone #{plaque_index} in #{parent}"
				all_points.each {|p| x,y=p; plaques[y][x] = parent}
			end
		end
	end
end

end