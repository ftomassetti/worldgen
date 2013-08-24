require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/images'
require 'worldgen/plaques'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/colors'

include WorldGen

def generate_continents_image(width,height,map,path,desc)
	begin
		colors = Colors.new
		save_image(width,height,path,desc) do |x,y|
			alt = map[y][x]		
			color = colors.get alt
			color = shadow_color(map,color,x,y)
		end
	rescue Exception => e
		puts "Problem with continents #{desc}: #{e}"
	end
end

(1..5).each do |seed|
	width = 300
	height = 300
	path = "examples/continental_base_#{seed}.contbase"
	map = load_marshal_file(path)
	outpath = "examples/continental_base_#{width}x#{height}_#{seed}.png"
	desc = "Continental base. Dim: #{width}x#{height}, Seed: #{seed}"
	generate_continents_image(width,height,map,outpath,desc)
end

(1..5).each do |seed|
	width = 1200
	height = 800
	path = "examples/continental_base_#{width}x#{height}_#{seed}_with_noise.contbase"
	map = load_marshal_file(path)
	outpath = "examples/continental_base_#{width}x#{height}_#{seed}_with_noise.png"
	desc = "Continental base with noise. Dim: #{width}x#{height}, Seed: #{seed}"
	generate_continents_image(width,height,map,outpath,desc)
end

puts "done."