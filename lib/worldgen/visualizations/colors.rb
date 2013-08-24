require 'worldgen/math'

module WorldGen

def mix_color(a,b,p)
	ip = 1.0-p
	r = (p*a.red+ ip*b.red).to_i
	g = (p*a.green+ ip*b.green).to_i
	b = (p*a.blue+ ip*b.blue).to_i
	Color.new r,g,b
end

class Colors

	def initialize
		@calculated = {}
		@limits = [
			# [4000,255,255,255],
			# [3000,200,200,200],
			# [800,66,33,0],
			# [500,99,66,0],
			# [300,66,100,0],
			# [20,0,230,0],
			# [0,225,210,30]

			[6000,196,235,236], # extra-pale blue
			[5000,253,254,250], # white
			[4000,185,205,206], # white-gray
			[3000,184,121,31], # light brown
			[1500,92,63,21], # dark brown
			[950,27,153,36],  # light green
			[600,41,113,46],   # green
			[250,26,75,30],   # dark green
			[50,216,230,97],     # beach
			[0,6,89,6],
			[-200,70,230,200],
			[-4000,0,0,255],
			[-10000,37,14,128]
		]
	end

	def calc(alt)
		min_x = @limits.last[0]
		max_x = @limits.first[0]
		# ex. 3000
		return Color.new(@limits.last[1],@limits.last[2],@limits.last[3]) if alt<=min_x
		return Color.new(@limits.first[1],@limits.first[2],@limits.first[3]) if alt>=max_x
		li = -1
		@limits.each_with_index do |arr,i|
			a,r,g,b = arr
			li=i if alt>a and li==-1
		end
		# ex. li = 1
		delta = @limits[li-1][0]-@limits[li][0] # ex. 4000-1000 = 3000
		dalt = alt-@limits[li][0] # ex. 3000-1000 = 2000
		p = dalt.to_f/delta.to_f # ex. 2000/3000 = 0.66
		ip = 1.0-p # ex. 0.33 =>  

		r = (p*@limits[li-1][1]+ ip*@limits[li][1]).to_i
		g = (p*@limits[li-1][2]+ ip*@limits[li][2]).to_i
		b = (p*@limits[li-1][3]+ ip*@limits[li][3]).to_i
		Color.new r,g,b
	end

	def get(alt)
		@calculated[alt] = calc(alt) unless @calculated[alt]
		@calculated[alt]
	end

end

class BwColors < Colors
	def initialize
		@calculated = {}
		@limits = [
			[4000,255,255,255],
			[0,0,0,0]
		]
	end
end

class RadiantColors < Colors
	def initialize
		@calculated = {}
		@limits = [
			[1.5*Math::PI,255, 255, 0],
			[1.0*Math::PI,  0,  0,255],
			[0.5*Math::PI,  0,255,  0],
			[0.0*Math::PI,255,  0,  0]
		]
	end
end

class TemperatureColors < Colors
	def initialize
		@calculated = {}
		@limits = [
			[1.0,255,  0,   0],
			[0.0,  0,  0, 255]
		]
	end
end

class GraduatedColors < Colors

	def initialize(n_colors)
		super()
		@n_colors = n_colors
		@n_color_intervals = (cube_root(n_colors).floor) +1
		@color_mul = 255.0/@n_color_intervals.to_f
	end

	def calc(val)
		val_in_base = to_base(val,@n_color_intervals,3)
		r = @color_mul * val_in_base[2]
		g = @color_mul * val_in_base[1]
		b = @color_mul * val_in_base[0]
		Color.new r.to_i,g.to_i,b.to_i
	end

end

end