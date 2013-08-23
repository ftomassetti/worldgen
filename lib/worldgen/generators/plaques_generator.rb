# Program to perform initial generation of plaques

require 'worldgen/visualizations/map_drawing'
require 'worldgen/plaques'
require 'worldgen/math'

include WorldGen

def perfom_generation(width,height,n_hot_points,disturb_strength,seed)
	plaques = generate_plaques(width,height,n_hot_points,disturb_strength,seed)

	n_color_intervals = (cube_root(n_hot_points).floor) +1
	color_mul = 255.0/n_color_intervals.to_f
	draw_code = Proc.new do |x,y|
		plaque_index = plaques[y][x]
		plaque_index_in_base = to_base(plaque_index,n_color_intervals,3)
		r = color_mul * plaque_index_in_base[2]
		g = color_mul * plaque_index_in_base[1]
		b = color_mul * plaque_index_in_base[0]
		color = Color.new r.to_i,g.to_i,b.to_i
		color
	end

	outpath = "plaques_#{width}x#{height}_hp#{n_hot_points}_seed#{seed}.plaques"
	File.open(outpath, 'wb') {|file| Marshal.dump(plaques,file) } 

	mf = MapFrame.new("Plaques seed #{seed}", width, height, draw_code)
	mf.launch
end

(1..5).each {|seed| perfom_generation(300,300,35,25,seed) }

puts "done."