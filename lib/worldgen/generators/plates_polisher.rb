# Program to polish plaques

require 'worldgen/plates'
require 'worldgen/math'
require 'worldgen/marshalling'
require 'worldgen/visualizations/map_drawing'
require 'worldgen/visualizations/colors'
require 'worldgen/console'

include WorldGen

$SAVING = true
$SHOW   = true

$USAGE = "plates_polisher <input> <output>"

show_usage if ARGV.count<2 
$INPUT  = ARGV[0]
$OUTPUT = ARGV[1]

ARGV[2..-1].each do |arg|
	name,value = arg.split ':'
	error "Unknown param: #{name}"
end

def perfom_polishing(plates)
	polished_map = plates.duplicate($OUTPUT)
	polish_plates(polished_map)
	defragment_plates(polished_map)

	n_plates = number_of_plates(polished_map)
	
	if $SAVING
		polished_map.save
	end

	if $SHOW
		colors = GraduatedColors.new n_plates
		draw_code = Proc.new do |x,y|
			plate_index = polished_map.get(x,y)		
			colors.get plate_index
		end
		mf = MapFrame.new("Polished plates", polished_map.width, polished_map.height, draw_code)
		mf.launch
	end
end

plates = Map.load($INPUT,:short)
log "Unpolished plates loaded"
perfom_polishing(plates)

puts "done."