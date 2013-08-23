require 'set'
require 'perlin_noise'
require 'worldgen/log'
require 'worldgen/geometry'
require 'worldgen/map'

module WorldGen

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

end