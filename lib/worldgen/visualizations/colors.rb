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

			[6000,245,245,255],
			[4000,253,254,250],
			[3000,250,240,200],
			[2000,206,186,146],
			[1000,247,253,160],
			[750,225,231,140],
			[500,171,160,48],
			[250,141,135,73],
			[125,14,128,14],
			[0,6,89,6],
			[-200,70,230,200],
			[-4000,0,0,255],
			[-10000,37,14,128]

			#[4000,255,255,255],
			#[0,0,0,0]
		]
	end

	def calc(alt)
		# ex. 3000
		return Color.new(0,0,255) if alt<=-10000
		return Color.new(245,245,255) if alt>=6000
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