module WorldGen

	def surroundings(p,radius)
        s = []
        px,py = p
        (-radius..radius).each do |dy|
            (-radius..radius).each do |dx|
                d = Math.sqrt(dx**2+dy**2)
                if d<=radius
                    x = px+dx
                    y = py+dy
                    np = [x,y]
                    s << np unless p.eql?np# or s.include?(np)
                end     
            end     
        end
        s
    end

	def each_around_limited(p,&block)
		x,y = p
		dirs = [ [0,-1],[1,0],[0,1],[-1,0] ]
		dirs.each do |d|
			dx,dy = d 
			block.call(dx+x,dy+y)
		end
	end

	def each_around(p,&block)
		x,y = p
		dirs = [ [0,-1],[1,-1],[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1]]
		dirs.each do |d|
			dx,dy = d 
			block.call(dx+x,dy+y)
		end
	end

	def north(p,d=1)
		x,y = p
		[x,y-d]
	end

	def south(p,d=1)
		x,y = p
		[x,y+d]
	end

	def east(p,d=1)
		x,y = p
		[x+d,y]
	end

	def west(p,d=1)
		x,y = p
		[x-d,y]
	end

	def distance(a,b,pow=2)
		dx = a[0]-b[0]
		dy = a[1]-b[1]
		Math.sqrt((dx**pow)+(dy**pow))
	end

	class Position
		attr_accessor :x
		attr_accessor :y

		def self.load(hash)
			inst = Position.new
			inst.x = hash['x']
			inst.y = hash['y']
			inst
		end

	end

	class Rectangle
		def initialize(r,t,l=0,b=0)
			@right = r
			@top = t
			@left = l
			@bottom = b
		end

		def width
			@right-@left
		end

		def height
			@top-@bottom
		end
		
		def random_point(random_source=Random.new)
			dx = @right-@left
			dy = @top-@bottom
			[random_source.rand(dx)+@left,random_source.rand(dy)+@bottom]
		end

		def each(&block)
			(@bottom..(@top-1)).each do |y|
				(@left..(@right-1)).each do |x|
					block.call(x,y)
				end
			end
		end

		def each_border_point(&block)
			# top
			(@left..(@right-1)).each {|x| block.call(x,@top-1)}
			# bottom
			(@left..(@right-1)).each {|x| block.call(x,@bottom)}
			# left
			(@bottom..(@top-1)).each {|y| block.call(@left,y)}
			# right
			(@bottom..(@top-1)).each {|y| block.call(@right-1,y)}
		end

		def include?(p)
			x,y = p
			x>=@left and y>=@bottom and x<@right and y<@top
		end

	end

end