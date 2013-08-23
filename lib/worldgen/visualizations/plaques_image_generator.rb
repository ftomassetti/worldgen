require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/images'
require 'worldgen/plaques'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/colors'

include WorldGen

def generate_plaques_image(width,height,plaques,path,desc)
	n_plaques = number_of_plaques(width,height,plaques)
	colors = GraduatedColors.new n_plaques
	save_image(width,height,path,desc) do |x,y|
		plaque_index = plaques[y][x]		
		colors.get plaque_index
	end
end

(1..5).each do |seed|
	width = 300
	height = 300
	n_hot_points = 35 
	path = "examples/plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.plaques"
	plaques = load_marshal_file(path)
	outpath = "examples/plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.png"
	desc = "Plaques unpolished. Dim: #{width}x#{height}, Hot Points: #{n_hot_points}, Seed: #{seed}"
	generate_plaques_image(width,height,plaques,outpath,desc)
end

(1..5).each do |seed|
	width = 300
	height = 300
	n_hot_points = 35 
	path = "examples/plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}_polished.plaques"
	plaques = load_marshal_file(path)
	outpath = "examples/plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}_polished.png"
	desc = "Plaques polished. Dim: #{width}x#{height}, Hot Points: #{n_hot_points}, Seed: #{seed}"
	generate_plaques_image(width,height,plaques,outpath,desc)
end

puts "done."