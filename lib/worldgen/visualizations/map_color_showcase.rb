# Show a map with all the possible altitudes

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/map'

include WorldGen

$WIDTH = 1000
$HEIGHT = 100

def gen_map
	min_height = -10000.0
	max_height =   7000.0
	delta_height = max_height-min_height
	w = $WIDTH
	build_map(w,$HEIGHT) do |x,y|
		p = x.to_f/w.to_f
		alt = delta_height*p + min_height
		alt
	end
end

map = gen_map
colors = Colors.new
draw_code = Proc.new do |x,y|
	alt = map[y][x]
	if (alt%1000).abs <= 25 and y%5==0
		Color.new 255,0,0
	else
		colors.get(alt)
	end
end

mf = MapFrame.new("Map colors showcase", $WIDTH, $HEIGHT, draw_code)
mf.launch