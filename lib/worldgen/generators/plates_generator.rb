# Program to perform initial generation of plaques

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'

include WorldGen

$SAVING = true
$SHOW   = true

def perfom_generation(width,height,n_hot_points,disturb_strength,seed)
	plates = generate_plaques(width,height,n_hot_points,disturb_strength,seed)

	if $SAVING
		outpath = "examples/plates_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.plaques"
		File.open(outpath, 'wb') {|file| Marshal.dump(plates,file) } 
	end

	if $SHOW
		n_color_intervals = (cube_root(n_hot_points).floor) +1
		colors = GraduatedColors.new n_color_intervals
		draw_code = Proc.new do |x,y|
			plaque_index = plates[y][x]
			color = colors.get plaque_index
			color
		end
		mf = MapFrame.new("Plates seed #{seed}", width, height, draw_code)
		mf.launch
	end
end

perform_generation $WIDTH, $HEIGHT, $N_HOT_POINTS, $DISTURB_STRENGTH, $SEED

puts "done."