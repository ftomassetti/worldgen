$CLASSPATH << '../java/'
java_import 'noises.SimplexNoise'

module WorldGen

def simplex_noise(seed)
	sn = SimplexNoise.new
	sn.genGrad seed
	sn
end

class CombinedSimplex

def initialize(n_bands,seed,base_freq=1,interval=256)
	random = Random.new seed
	@base_freq = base_freq
	@perlins = []
	@n_bands = n_bands
	(0..(n_bands-1)).each {|i| @perlins[i] = simplex_noise(random.rand(65536)) }
end

def get(x,y)
	sum = 0
	sum_mul = 0
	freq = @base_freq
	(0..(@n_bands-1)).each do |band|
		v_band = @perlins[band].noise(x*freq,y*freq)
		freq *= 4
		mul = 4**(@n_bands-band-1) 
		sum += v_band*mul
		sum_mul += mul
	end    	
	v = (sum)/sum_mul.to_f
end

end

end