require 'set'
require 'perlin_noise'
require 'worldgen/log'
require 'worldgen/geometry'
require 'worldgen/map'
require 'worldgen/noises'

module WorldGen

def plates_at_border_of_the_map(plates)
	w = plates.width
	h = plates.height
	border_plates = Set.new
	Rectangle.new(w,h).each_border_point do |x,y|
		border_plates << plates.get(x,y)
	end
	border_plates
end

def plates(plates_map)
	plates = Set.new
	plates_map.each do |x,y,plaque_index|
		plates << plaque_index
	end
	plates
end

def number_of_plates(plates_map)
	plates(plates_map).count
end

#
# DEPRECATED: old version using the "array map"
#
def arraymap_number_of_plates(w,h,plates)
	max = -1
	each_in_map(w,h,plates) do |x,y,plaque_index|
		max=plaque_index if plaque_index>max
	end
	max+1
end

def defragment_plates(map)
	plates = plates(map)
	n_plates = plates.count
	conversion = {}
	plates.each do |i|
		conversion[i]=conversion.count
	end
	map.reassign_each do |x,y,old_i|
		conversion[old_i]
	end
end

def merge_plates(map,n_final_plates,r)
	# calculate how many plates there are
	plates = plates(map).to_a
	plate_sizes = {}
	plates.each do |p|
		plate_sizes[p] = points_of_the_plate(map,p).count
		raise "Zero points for plates #{p}" if plate_sizes[p]==0
	end

	raise "too few plates" if plates.count<n_final_plates
	puts "Number of plates: #{plates.count}, reducing to #{n_final_plates}"
	# loop until the number is reduced
	while plates.count>n_final_plates
		puts "Reduction (#{plates.count} plates)"
		# get a random plate
		# TODO, favor smaller plates
		small_plates = ((plate_sizes.sort_by { |k,v| v }).map{|k,v| k})[0..5]
		start_plate = small_plates[r.rand(small_plates.count)]
		# get a random point
		start_plate_points = points_of_the_plate(map,start_plate)
		raise "Plate #{start_plate} has zero points" if start_plate_points.count==0
		p = start_plate_points[r.rand(start_plate_points.count)]
		p = MapPoint.new(p[0],p[1],map)
		puts "\tStart plate #{start_plate} #{p}"
		# move in random direction until a different plate is reached
		while map.get(p.x,p.y)==start_plate
			p = p.move_randomly(r)
			#puts "\t\tmoving to #{p}"			
		end
		end_plate = map.get(p.x,p.y)
		puts "\tend plate #{end_plate}"
		# merge the two plates
		map.reassign_each do |x,y,index|
			if index==end_plate
				start_plate
			else
				index
			end
		end
		plates.delete(end_plate)
		rem = plate_sizes.delete(end_plate)
		plate_sizes[start_plate] += rem 
		puts "\treassign done"
	end
end

def points_of_plaque(w,h,map,index)
	points = []
	Rectangle.new(w,h).each do |x,y|
		points << [x,y] if map[y][x]==index
	end
	points
end

def generate_plates(width,height,n_hot_points,disturb_strength=25,seed)
	log "generate plates started: dim=#{width}x#{height}, n_hot_points: #{n_hot_points}, seed: #{seed}"
	general_random = Random.new seed
	log "generating hot points"
	hot_points = gen_hot_points(width,height,n_hot_points,Random.new(general_random.seed))
	log "building distances map"
	distances_map = calc_hotpoints_distances_map(width,height,hot_points)
	if disturb_strength>0
		log "disturbing distances map"
		disturb_distances_map(width,height,hot_points,distances_map,disturb_strength,general_random.rand(100000))
	else
		derive_map_from_map(distances_map,width,height,'deriving plates map from distances map') do |x,y,distances|
			max = width*height
			sel_i = 0
			hot_points.each_with_index do |hp,i|
				tot = distances[i]
				if tot<max
					sel_i = i
					max = tot
				end
			end
			sel_i
		end
	end	
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

def disturb_distances_map(w,h,hot_points,distances_map,disturb_strength,seed)
	noises = []
	r = Random.new seed
	#hot_points.count.times { noises << Perlin::Noise.new(2, :interval => [w,h].max) }
	hot_points.count.times { noises << simplex_noise(r.rand(100000)) }
	derive_map_from_map(distances_map,w,h,'inserting noise in distances map') do |x,y,distances|
		max = w*h
		sel_i = 0
		hot_points.each_with_index do |hp,i|
			noise_source = noises[i]
			px = 8.0*(x.to_f/w.to_f)
			py = 8.0*(y.to_f/h.to_f)
			#puts "NOISE: #{noise_source.noise(py,px)}"
			#tot = distances[i]+disturb_strength.to_f*noise_source[py,px]
			tot = distances[i]+disturb_strength.to_f*noise_source.noise(py,px)
			if tot<max
				sel_i = i
				max = tot
			end
		end
		sel_i
	end
end

def polish_plates(plates)
	log "Breaking plates in blocks"
	break_plates_in_blocks(plates)
	log "Inglobing surrounded block"
	inglobe_surrounded_blocks(plates)
end

def points_of_the_plate(plates_map,plate_index)
	points = []
	plates_map.each do |x,y,val|
		points << [x,y] if val==plate_index
	end
	points
end

def arraymap_points_of_the_plaque(w,h,plates,plaque_index)
	points = []
	each_in_map(w,h,plates) do |x,y,val|
		points << [x,y] if val==plaque_index
	end
	points
end

def expand_around_point(map,block,p,val)
	w = map.width
	h = map.height
	r = Rectangle.new w,h
	each_around_limited(p) do |x,y|
		p = [x,y]
		#puts "Considering #{x},#{y} arounf #{p[0]},#{p[1]} #{r.include?([x,y])} #{map[y][x] == val}"
		block << p if r.include?([x,y]) and (map.get(x,y) == val) and (not block.include?([x,y]))
	end
end

def expand_block(map,block,p,val)
	block << p
	i = 0
	while i<block.count
		puts "exp #{i}" if i%100==0
		expand_around_point(map,block,block[i],val)
		i+=1
	end
end

# Each plaque having not contiguos points is broken
def break_plates_in_blocks(plates)
	n_plates = number_of_plates(plates)
	plaque_index=0
	while plaque_index<n_plates
		log "breaking plate #{plaque_index}"
		all_points = points_of_the_plate(plates,plaque_index)
		if all_points.count>0
			start_point = all_points[0]
			main_block = []
			expand_block(plates,main_block,start_point,plaque_index)
			toremove = all_points.select {|p| not main_block.include? p}			
			if toremove.count>0
				log "plate to be broken, #{toremove.count} points removed, #{main_block.count} kept"
				toremove.each {|p| x,y=p; plates.set(x,y,n_plates)}
				n_plates += 1				
			end			
		end
		plaque_index += 1
	end
end

def get_first_neighbor_in_dir(plates,start_point,dir)
	x,y = start_point
	my_plaque_index = plates.get(x,y)

	while true
		next_x = x+dir[0]
		next_y = y+dir[1]
		next_point = [next_x,next_y]
		if Rectangle.new(plates.width,plates.height).include?(next_point)
			other_plaque_index = plates.get(next_x,next_y)
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

def get_first_neighbors_in_all_dirs(plates,start_point)
	[get_first_neighbor_in_dir(plates,start_point,[0,-1]),
		get_first_neighbor_in_dir(plates,start_point,[1,0]),
		get_first_neighbor_in_dir(plates,start_point,[0,1]),
		get_first_neighbor_in_dir(plates,start_point,[-1,0])]
end

def container_inglobing_points(plates,all_points)
	all_neighbors = []
	all_points.each do |p|
		new_neighbours = get_first_neighbors_in_all_dirs(plates,p)
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
def inglobe_surrounded_blocks(plates)
	n_plates = number_of_plates(plates)
	n_plates.times do |plaque_index|
		log "considering for inglobation #{plaque_index}"
		all_points = points_of_the_plate(plates,plaque_index)		
		if all_points.count>0						
			parent = container_inglobing_points(plates,all_points)
			if parent
				# ok, inglobe
				log "Going to inglone #{plaque_index} in #{parent}"
				all_points.each {|p| x,y=p; plates.set(x,y,parent)}
			end
		end
	end
end

end