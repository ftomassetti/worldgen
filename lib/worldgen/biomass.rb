module WorldGen

ELEVATION_TYPES = [:ocean, :flatland, :hill, :low_mountain, :medium_mountain, :high_mountain]
TEMPERATURE_TYPES = [:really_cold, :cold, :temperate, :warm, :really_warm]
HUMIDITY_TYPES = [:ocean,:arid,:semi_arid,:moderate,:semi_wet,:wet]

def elevation_type(elev)
	if elev<0
		:ocean
	elsif elev<500
		:flatland
	elsif elev<650
		:hill
	elsif elev<1200
		:low_mountain
	elsif elev<2000
		:medium_mountain
	else
		:high_mountain
	end
end

def temperature_type(temp)
	if temp <0.2
		:really_cold
	elsif temp <0.4
		:cold
	elsif temp <0.6
		:temperate
	elsif temp <0.8
		:warm
	else
		:really_warm
	end
end

def humidity_type(water_amount)
	if water_amount == -1.0
		:ocean
	elsif water_amount < 0.5
		:arid
	elsif water_amount < 2
		:semi_arid
	elsif water_amount < 4
		:moderate
	elsif water_amount < 6
		:semi_wet
	else
		:wet
	end
end

def biome_type(et,tt,ht)
	warmp    = (tt==:warm or tt==:really_warm)
	aridp    = (ht==:arid or ht==:semi_arid)
	semiwetp = (ht==:semi_wet or ht==:wet)
	mountains = (et==:low_mountain or et==:medium_mountain)

	if et==:ocean or ht==:ocean
		:ocean
	elsif et==:high_mountain
		:glacier
	elsif warmp and semiwetp
		:tropical_jungle
	elsif warmp and ht==:moderate
		:jungle
	elsif (et==:flatland or et==:hill) and (tt==:temperate)
		:forest
	elsif mountains and (tt==:cold or tt==:temperate)
		:coniferous_forest
	elsif tt==:cold and semiwetp 
		:taiga
	elsif tt==:really_cold and (semiwetp or ht==:moderate)
		:tundra
	elsif (ht==:semi_arid) and (tt==:really_warm or tt==:warm)
		:savanna
	elsif (ht==:arid or ht==:semi_arid) and (tt==:really_cold)
		:iceland
	elsif (et==:flatland or et==:hill) and (ht==:semi_arid or ht==:arid) and tt==:cold
		:steppa
	elsif ht==:arid and tt==:really_warm
		:desert
	elsif ht==:arid and (tt==:warm or tt==:temperate)
		:rocky_desert
	elsif et==:flatland and (tt==:cold) and (ht==:moderate or ht==:semi_wet)
		:grass
	elsif et==:low_mountain and tt==:temperate and (ht==:moderate or ht==:semi_wet)
		:alpine
	elsif mountains and aridp
		:rocky_mountain
	elsif ht==:wet and (tt==:cold or tt==:temperate)
		:swamp
	else
		:unknown
	end
end

end