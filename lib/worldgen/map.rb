require 'worldgen/log'

module WorldGen

def print_map(w,h,map,title)
	puts "= map #{title} ="
	h.times do |y|
		print "#{y}] "
		w.times {|x| print "#{map[y][x]} "}
		print "\n"
	end
end

def each_in_map(w,h,map,&block)
	h.times do |y|
		w.times do |x|
			block.call(x,y,map[y][x])			
		end
	end
end

def build_map(w,h,desc=nil,&block)
	alt = []
	h.times do |y|
		log "#{desc}, line #{y} of #{h}" if y%STEP_LINES==0 and desc
		row = []
		w.times.each do |x|
			row[x] = block.call(x,y)			
		end
		alt[y] = row
	end
	alt
end

def build_fixed_map(w,h,value=0.0)
	build_map(w,h) {|x,y| value }
end

def derive_map_from_map(orig,width,height,desc=nil,&block)
	build_map(width,height,desc) do |x,y|
		block.call(x,y,orig[y][x])
	end
end

def rescale(curr,curr_w,curr_h,desired_w,desired_h)
	build_map(desired_w,desired_h) do |x,y|
		original_x = ((x.to_f/desired_w.to_f)*curr_w).floor
		original_y = ((y.to_f/desired_h.to_f)*curr_h).floor
		curr[original_y][original_x]
	end
end

def antialias!(map,w,h,ntimes=1)
	Rectangle.new(w,h).each do |x,y|
		log "antialiasing #{ntimes}, y=#{y}" if x==0 and (y%25)==0
		sum = 0
		n = 0
		each_around([x,y]) do |ax,ay|
			if ax>=0 and ay>=0 and ax<w and ay<h
				n+=1
				sum+=map[ay][ax]
			end
		end
		map[y][x] = (sum.to_f/n.to_f).to_i
	end
	antialias!(map,w,h,ntimes-1) if ntimes>1
end

end