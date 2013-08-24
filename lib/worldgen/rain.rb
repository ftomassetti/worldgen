module WorldGen

def invert_radiant_dir(dir)
	(dir+Math::PI)%(2*Math::PI)
end

def radiant_dir_to_discrete_dir(radiant_dir)
	conv = {
		0.00*Math::PI => [ 0,-1],
		0.25*Math::PI => [ 1,-1],
		0.50*Math::PI => [ 1, 0],
		0.75*Math::PI => [ 1, 1],
		1.00*Math::PI => [ 0, 1],
		1.25*Math::PI => [-1, 1],
		1.50*Math::PI => [-1, 0],
		1.75*Math::PI => [-1,-1]
	}
	min_dist = 100
	res = nil
	conv.each do |k,v|
		dist = (radiant_dir-k).abs
		if dist<min_dist
			min_dist = dist
			res = v
		end
	end
	res
end

def move_contrary_to_wind(p,wind_map)
	wind_dir = wind_map[p[1]][p[0]]
	id = invert_radiant_dir(wind_dir)
	disc_dir = radiant_dir_to_discrete_dir(id)
	[p[0]+disc_dir[0],p[1]+disc_dir[1]]
end

def grow_path_to_water(p,elev_map,wind_map,to_ocean_path)
	x,y = p
	elev = elev_map[y][x]
	return [] if elev<0
	dest = move_contrary_to_wind(p,wind_map)
	[p].concat( to_ocean_path[dest] )
end

def rain_shadow_effect(my_elev,obstacle_elev,dist)
	return 0.0 if my_elev>=obstacle_elev
	return 0.0 if obstacle_elev<1000
	if obstacle_elev>3000
		strength = 1.0 
	else
		strength = (obstacle_elev-1000).to_f/2000.to_f
	end

	return 0.0 if dist>70
	return strength*(1.0-(dist/20.0))
end

def rain_shadow_from_path(path,elev_map,elev)
	rs_max = 0.0
	path.each_with_index do |obstacle_pos,dist|
		ox,oy = obstacle_pos
		rs = rain_shadow_effect(elev,elev_map[oy][ox],dist)
		rs_max = rs if rs>rs_max
	end
	rs_max
end

def calc_rain_shadow(w,h,elev_map,wind_map)
	to_ocean_path = Hash.new do |hash,p|
		hash[p] = grow_path_to_water(p,elev_map,wind_map,hash)
	end
	build_map(w,h) do |x,y|
		log "wind map #{y}" if x==0 and y%25==0
		if elev_map[y][x]<0
			-1.0
		else
			rain_shadow_from_path(to_ocean_path[[x,y]],elev_map,elev_map[y][x])
		end
	end
end

end