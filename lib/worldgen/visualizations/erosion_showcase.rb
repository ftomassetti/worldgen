# Show erosion in action

require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/map'
require 'worldgen/erosion'

include WorldGen

$WIDTH  = 3
$HEIGHT = 3

def gen_map
	map = build_fixed_map($WIDTH,$HEIGHT)
	map[0][0] = 3000
	map[0][1] = map[1][0] = 2000
	map[1][1] = 1800
	map[0][2] = map[2][0] = 1500
	map[1][2] = map[2][1] = -500
	map[2][2] = -50
	map
end

map = gen_map
print_map($WIDTH,$HEIGHT,map,"Initial map")
water_map,sediment_map =erosion($WIDTH,$HEIGHT,map,1)
print_map($WIDTH,$HEIGHT,map,"Final map")

print_map($WIDTH,$HEIGHT,water_map,"Water map")
print_map($WIDTH,$HEIGHT,sediment_map,"Sediment map")
