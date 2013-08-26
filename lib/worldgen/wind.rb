require 'set'
require 'worldgen/noises'
require 'worldgen/log'
require 'worldgen/geometry'
require 'worldgen/map'
require 'worldgen/gradient'

module WorldGen

NORTH_DIR = Math::PI*0.0
EAST_DIR  = Math::PI*0.5
SOUTH_DIR = Math::PI*1.0
WEST_DIR  = Math::PI*1.5

def gen_wind_samples(h)
	wind_samples = [
		[1.000*h.to_f, SOUTH_DIR],  # north pole
		[0.800*h.to_f, NORTH_DIR],  # north circle
		[0.650*h.to_f, EAST_DIR],   # north tropic
		[0.500*h.to_f, WEST_DIR] ,  # equator
		[0.350*h.to_f, EAST_DIR],   # south_tropic
		[0.200*h.to_f, SOUTH_DIR],  # south_circle
		[0.000*h.to_f, NORTH_DIR]   # south_pole
	]
end

def wind_dir(wind_samples,y)	
	gradient_numbers(wind_samples,y)
end

def gen_wind_map(w,h,elev_map,seed)
	wind_samples = gen_wind_samples(h)
	noise_source = simplex_noise seed
	noise_source_b = simplex_noise seed+1
	build_map(w,h,'wind map') do |x,y|
		calc_dir = wind_dir(wind_samples,y)
		px = 2.0*x.to_f/w.to_f
		py = 2.0*y.to_f/h.to_f
		noise = noise_source.noise(px,py)*Math::PI*0.7+noise_source_b.noise(px,py)*Math::PI*0.7
		val = calc_dir+noise
		val % (Math::PI*2.0)
	end
end

end