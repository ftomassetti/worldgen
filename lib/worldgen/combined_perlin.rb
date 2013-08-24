require 'perlin_noise'

module WorldGen

class CombinedPerlin

	def initialize(n_bands,seed,base_freq=1,interval=256,contrasts=nil)
		random = Random.new seed
		if contrasts
			raise 'wrong contrasts size' unless contrasts.count==n_bands
			@contrasts = contrasts.map {|c| Perlin::Curve.contrast(Perlin::Curve::CUBIC, c)}
		else
			@contrasts = nil
		end
		@base_freq = base_freq
		@perlins = []
		@n_bands = n_bands
		(0..(n_bands-1)).each {|i| @perlins[i] = Perlin::Noise.new 2, :interval => interval, :seed => random.rand }
	end

	def get(x,y)
		sum = 0
		sum_mul = 0
		freq = @base_freq
		(0..(@n_bands-1)).each do |band|
			v_band = @perlins[band][x*freq,y*freq]
			if @contrasts
				v_band = @contrasts[band].call v_band
			end
			freq *= 4
			mul = 4**(@n_bands-band-1) 
			sum += v_band*mul
			sum_mul += mul
		end    	
    	v = (sum)/sum_mul.to_f
	end

end

end