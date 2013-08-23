# Program to polish plaques

require 'worldgen/visualizations/map_drawing'
require 'worldgen/plaques'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/colors'

include WorldGen

def perfom_polishing(width,height,plaques,name,seed)
	polish_plaques(width,height,plaques)

	n_plaques = number_of_plaques(width,height,plaques)
	colors = GraduatedColors.new n_plaques
	draw_code = Proc.new do |x,y|
		plaque_index = plaques[y][x]		
		colors.get plaque_index
	end

	outpath = "plaques_#{name}_polished.plaques"
	save_marshal_file(outpath,plaques)

	mf = MapFrame.new("Polished plaques seed #{seed}", width, height, draw_code)
	mf.launch
end

(1..5).each do |seed|
	log "Polishing plaques, seed #{seed}"
	width = 300
	height = 300
	n_hot_points = 35 
	path = "plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.plaques"
	plaques = load_marshal_file(path)
	log "Unpolished plaques loaded"

	perfom_polishing(width,height,plaques,"#{width}x#{height}_hp#{n_hot_points}_seed#{seed})",seed)
end

puts "done."