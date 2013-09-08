#
# Take a plates file and merge plates, making less and bigger plates
#

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/console'

include WorldGen

$SAVING = true
$SHOW   = true
$N_FINAL_PLATES = 20

$USAGE = "plates_grouper <seed> <input> <output>"

show_usage if ARGV.count<3 
$SEED   = ARGV[0].to_i
$INPUT = ARGV[1]
$OUTPUT = ARGV[2]

ARGV[3..-1].each do |arg|
	name,value = arg.split ':'
	case name
	when 'np'
		$N_FINAL_PLATES = value.to_i
	else
		error "Unknown param: #{name}"
	end
end

def perform_merging(original_map,n_final_plates,seed)
	merged_map = original_map.duplicate($OUTPUT)
	merge_plates(merged_map,n_final_plates,Random.new(seed))
	defragment_plates(merged_map)

	if $SAVING
		merged_map.save
		#save_marshal_file($OUTPUT, plates)
	end

	if $SHOW		
		n_color_intervals = (cube_root(number_of_plates(merged_map)).floor) +1
		colors = GraduatedColors.new n_color_intervals
		draw_code = Proc.new do |x,y|
			plaque_index = merged_map.get(x,y)
			color = colors.get plaque_index
			color
		end
		mf = MapFrame.new("Plates seed #{seed}", merged_map.width, merged_map.height, draw_code)
		mf.launch
	end
end

original_plates_map = Map.load($INPUT,:short)
perform_merging original_plates_map, $N_FINAL_PLATES, $SEED

puts "done."