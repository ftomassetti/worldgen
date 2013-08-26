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

def perfom_polishing(width,height,plates)
	polish_plates(width,height,plates)

	n_plaques = number_of_plaques(width,height,plates)
	
	if $SAVING
		save_marshal_file($OUTPUT,plates)
	end

	if $SHOW
		colors = GraduatedColors.new n_plaques
		draw_code = Proc.new do |x,y|
			plate_index = plates[y][x]		
			colors.get plate_index
		end
		mf = MapFrame.new("Polished plates", width, height, draw_code)
		mf.launch
	end
end

plates = load_marshal_file($INPUT)
log "Unpolished plates loaded"
width = map_width(plates)
height = map_height(plates)
perfom_polishing(width,height,plates)

puts "done."