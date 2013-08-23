module WorldGen

def build_map(w,h,desc='building a map',&block)
	alt = []
	(0..(h-1)).each do |y|
		log "#{desc}, line #{y} of #{h}" if y%STEP_LINES==0
		row = []
		(0..(w-1)).each do |x|
			row[x] = block.call(x,y)			
		end
		alt[y] = row
	end
	alt
end

def build_fixed_map(w,h,value=0.0)
	build_map(w,h) {|x,y| value }
end

def derive_map_from_map(orig,width,height,desc='deriving map from map',&block)
	build_map(width,height,desc) do |x,y|
		block.call(x,y,orig[y][x])
	end
end

end