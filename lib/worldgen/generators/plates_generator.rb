# Program to perform initial generation of plaques

require 'worldgen/visualizations/map_drawing'
require 'worldgen/plaques'
require 'worldgen/math'

include WorldGen

$SAVING = false

def perfom_generation(width,height,n_hot_points,disturb_strength,seed)
	plates = generate_plaques(width,height,n_hot_points,disturb_strength,seed)

	n_color_intervals = (cube_root(n_hot_points).floor) +1
	colors = GraduatedColors.new n_color_intervals
	draw_code = Proc.new do |x,y|
		plaque_index = plates[y][x]
		color = colors.get plaque_index
		color
	end

	if $SAVING
		outpath = "plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.plaques"
		File.open(outpath, 'wb') {|file| Marshal.dump(plates,file) } 
	end

	mf = MapFrame.new("Plaques seed #{seed}", width, height, draw_code)
	mf.launch
end

(6..6).each {|seed| perfom_generation(300,300,35,25,seed) }

puts "done."