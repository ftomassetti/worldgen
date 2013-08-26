require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/continents'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/erosion'
require 'worldgen/console'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "erosion_generator <elev> <rainshadow> <output> <seed> <iterations>"

show_usage if ARGV.count<5
$INPUT_ELEV  = ARGV[0]
$INPUT_RAINSH  = ARGV[1]
$OUTPUT = ARGV[2]
$SEED   = ARGV[3].to_i
$ITERATIONS = ARGV[4].to_i

ARGV[5..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def perform_erosion(w,h,map,rainshadow_map,seed)
	log "Starting erosion"

	erodibility_ns = CombinedSimplex.new 2,seed*11,4,256
	erodibility_map = build_map(w,h) do |x,y|
		puts "building erodibility map #{y}" if y%100==0 and x==0
		xp = 64.0*(x.to_f/w.to_f)
		yp = 64.0*(y.to_f/h.to_f)
		erodibility_ns.get xp,yp
	end
	log "Erodibility map created"

	rs = Random.new seed*7
	water_map = particles_erosion(w,h,map,erodibility_map,rainshadow_map,rs,$ITERATIONS)

	n_land_with_water = 0
	n_land_without_water = 0
	each_in_map(w,h,water_map) do |x,y,v|
		if map[y][x]>=0.0
			if v>0
				n_land_with_water+=1
			else
				n_land_without_water+=1
			end
		end
	end
	puts "Land with water: #{n_land_with_water}"
	puts "Land without water: #{n_land_without_water}"

	if $SAVING
		data = {:erodibility=>erodibility_map, :water_map =>water_map, :elevation => map }
		save_marshal_file($OUTPUT,data)
	end
	
	if $SHOW
		colors = Colors.new
		draw_code = Proc.new do |x,y|
			color = colors.get(map[y][x])
			color = shadow_color(map,color,x,y)
		end

		mf = MapFrame.new("Erosion, seed #{seed}", w, h, draw_code)
		mf.launch
	end
end

(6..6).each do |seed| 
	w = 1200
	h = 800
	path = "examples/continental_base_#{w}x#{h}_#{seed}_with_noise.contbase"
	map = load_marshal_file(path)
	rainshadow_map = load_marshal_file("examples/rainshadowmap_#{w}x#{h}_#{seed}.rainshadow")
	perform_erosion(w,h,map,rainshadow_map,seed) 
end

puts "done."