$CLASSPATH << '../java/'
java_import 'noises.SimplexNoise'

module WorldGen

	def simplex_noise(seed)
		sn = SimplexNoise.new
		sn.genGrad seed
		sn
	end

end