require 'set'
require 'perlin_noise'
require 'worldgen/log'
require 'worldgen/geometry'
require 'worldgen/map'
require 'worldgen/gradient'

module WorldGen

TEMP_ELEV_SAMPLES = [
	[10000, 0.10],
	[7000,  0.20],
	[4000,  0.30],
	[3000,  0.50],
	[2000,  0.65],
	[1000,  0.80],
	[700,   0.90],
	[0,     1.00]
]

def temperature_at_latitude(h,y)
	equator_dist = (y-h/2).abs
	pole_dist = h/2 - equator_dist
	(pole_dist.to_f*2.0)/h.to_f
end

def temperature_at_elevation(elev)
	gradient_numbers(TEMP_ELEV_SAMPLES,elev)
end

def gen_temperature_map(w,h,elev_map,seed)
	noise_source = Perlin::Noise.new 2, :seed => seed*3
	build_map(w,h,'temp map') do |x,y|
		lat_temp = temperature_at_latitude(h,y)
		elev_temp = temperature_at_elevation(elev_map[y][x])
		px = 8.0*x.to_f/w.to_f
		py = 8.0*y.to_f/h.to_f
		noise = (((noise_source[px,py])*0.2)-0.1)/1.0
		val = lat_temp*elev_temp+noise
		val
	end
end

end