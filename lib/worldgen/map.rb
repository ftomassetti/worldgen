require 'worldgen/log'
require 'worldgen/geometry'

java_import java.nio.channels.FileChannel
java_import java.io.RandomAccessFile

module WorldGen

class MapPoint
	attr_accessor :x
	attr_accessor :y

	def initialize(x,y,map)
		@x = x
		@y = y
		@map = map
	end

	def move_randomly(r=Random.new)
		dx = nil
		dy = nil
		#puts "Move randomly start"
		while (!dx) || (!dy) || (!@map.is_contained(dx,dy))
			dir_x,dir_y = DIRS[r.rand(8)]
			dx = @x+dir_x
			dy = @y+dir_y
			#puts "\tsel dx:#{dx} dy:#{dy}"
		end 
		#puts "Move randomly end"
		MapPoint.new(dx,dy,@map)
	end

	def to_s
		"(#{x},#{y})"
	end

end

class Map
	attr_accessor :width
	attr_accessor :height
	attr_accessor :mbb
	attr_accessor :type

	def self.type_size(type)
		if type==:short
			2
		elsif type==:float
			4			
		else
			raise "Unknown type"
		end		
	end

	def derive_map(path,type=:float,desc=nil,&block)
		Map.create_map(path,@width,@height,type,desc) do |x,y|
			block.call(x,y,get(x,y))
		end
	end

	def self.create_map(path,width,height,type=:float,desc=nil,&block)
		rac = RandomAccessFile.new path, 'rw'
		fc = rac.channel
		rw_mode = FileChannel::MapMode::READ_WRITE
		size = Map.type_size(type)*width*height
		mbb_metadata = fc.map rw_mode, 0, 4
		mbb_metadata.putShort width
		mbb_metadata.putShort height
		mbb_values = fc.map rw_mode, 4, size
		height.times do |y|
			width.times do |x|
				v = block.call(x,y)
				if type==:short
					mbb_values.putShort v
				elsif type==:float
					mbb_values.putFloat v
				else
					raise "Unknown type"
				end
			end
		end
		map = Map.new
		map.width = width
		map.height = height
		map.mbb = mbb_values
		map.type = type 
		map
	end

	def self.from_array(array,path,type=:short)
		rac = RandomAccessFile.new path, 'rw'
		fc = rac.channel
		rw_mode = FileChannel::MapMode::READ_WRITE
		width  = map_width(array)
		height = map_height(array)
		size = Map.type_size(type)*width*height
		mbb_metadata = fc.map rw_mode, 0, 4
		mbb_metadata.putShort width
		mbb_metadata.putShort height
		mbb_values = fc.map rw_mode, 4, size
		for y in 0..(height-1)
			for x in 0..(width-1)
				if type==:short
					mbb_values.putShort array[y][x]
				elsif type==:float
					mbb_values.putFloat array[y][x]
				else
					raise "Unknown type"
				end
			end
		end
		map = Map.new
		map.width = width
		map.height = height
		map.mbb = mbb_values
		map.type = type 
		map
	end

	def self.load(path,type=:float)
		rac = RandomAccessFile.new path, 'rw'
		fc = rac.channel
		rw_mode = FileChannel::MapMode::READ_WRITE
		mbb_metadata = fc.map rw_mode, 0, 4
		mbb_values = fc.map rw_mode, 4, fc.size-4
		map = Map.new
		map.width = mbb_metadata.getShort 0
		map.height = mbb_metadata.getShort 2
		map.mbb = mbb_values 
		map.type = type
		map
	end

	def duplicate(path)
		rac = RandomAccessFile.new path, 'rw'
		fc = rac.channel
		rw_mode = FileChannel::MapMode::READ_WRITE
		width  = @width
		height = @height
		size = Map.type_size(type)*width*height
		mbb_metadata = fc.map rw_mode, 0, 4
		mbb_metadata.putShort width
		mbb_metadata.putShort height
		mbb_values = fc.map rw_mode, 4, size
		height.times do |y|
			width.times do |x|
				v = self.get(x,y)
				if type==:short
					mbb_values.putShort v
				elsif type==:float
					mbb_values.putFloat v
				else
					raise "Unknown type"
				end
			end
		end
		map = Map.new
		map.width = width
		map.height = height
		map.mbb = mbb_values
		map.type = @type 
		map
	end

	def close
		@mbb.close
	end

	def save
		@mbb.force#(true)
	end

	def is_contained(x,y=nil)
		if y==nil
			x,y = x
		end
		x>=0 && y>=0 && x<@width && y<@height
	end

	def get(x,y=nil)
		if y==nil
			x,y = x
		end
		raise "unvalid point" if x<0 or y<0 or x>=@width or y>=@height
		#puts "x=#{x},y=#{y},"		
		if type==:short
			@mbb.getShort(((y*@width)<<1)+(x<<1))
		elsif type==:float
			@mbb.getFloat(((y*@width)<<2)+(x<<2))
		else
			raise "Unknown type"
		end
	end

	def set(x,y=nil,val)
		if y==nil
			x,y = x
		end
		raise "unvalid point" if x<0 or y<0 or x>=@width or y>=@height		
		if type==:short
			@mbb.putShort(((y*@width)<<1)+(x<<1),val)
		elsif type==:float
			@mbb.putFloat(((y*@width)<<2)+(x<<2),val)
		else
			raise "Unknown type"
		end	
	end

	def each(&block)
		@height.times do |y|
			@width.times do |x|
				block.call(x,y,get(x,y))			
			end
		end
	end

	def reassign_each(&block)
		@height.times do |y|
			@width.times do |x|
				set(x,y,block.call(x,y,get(x,y)))			
			end
		end
	end		

	def random_point(r=Random.new)
		MapPoint.new(r.rand(@width),r.rand(@height),self)
	end

	def rescale(output,desired_w,desired_h,type=self.type)
		Map.create_map(output,desired_w,desired_h,type) do |x,y|
			original_x = ((x.to_f/desired_w.to_f)*@width).floor
			original_y = ((y.to_f/desired_h.to_f)*@height).floor
			get(original_x,original_y)
		end
	end

	def antialias!(ntimes=1)
		w = @width
		h = @height
		Rectangle.new(w,h).each do |x,y|
			log "antialiasing #{ntimes}, y=#{y}" if x==0 and (y%25)==0
			sum = 0
			n = 0
			each_around([x,y]) do |ax,ay|
				if ax>=0 and ay>=0 and ax<w and ay<h
					n+=1
					sum+=get(ax,ay)
				end
			end
			set(x,y,(sum.to_f/n.to_f).to_i)
		end
		antialias!(ntimes-1) if ntimes>1
	end

end

def map_width(map)
	map[0].count
end

def map_height(map)
	map.count
end

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

end