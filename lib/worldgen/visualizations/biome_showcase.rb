require 'worldgen/biomass'

include WorldGen

ELEVATION_TYPES.each do |et|
	TEMPERATURE_TYPES.each do |tt|
		HUMIDITY_TYPES.each do |ht|
			biome = biome_type(et,tt,ht)
			printf "%20s %20s %20s -> %s\n",et,tt,ht,biome
		end
	end
end