require 'worldgen/visualizations/colors'
require 'worldgen/visualizations/map_drawing'

java_import java.applet.Applet
java_import java.awt.font.FontRenderContext
java_import java.awt.geom.Rectangle2D
java_import java.net.URL
java_import javax.imageio.ImageIO
java_import javax.swing.JFrame
java_import java.awt.Dimension
java_import javax.swing.JPanel
java_import java.awt.Color
java_import java.awt.image.BufferedImage

module WorldGen

def save_image(w,h,outputfile,label=nil,&draw_code)
	if label
		total_h = h+20
	else
		total_h = h
	end
	image = BufferedImage.new(w,total_h, BufferedImage::TYPE_INT_ARGB)
	g = image.createGraphics

	class << g
		def set_pixel x,y,color
			self.color = color
			self.draw_line x,y,x,y
		end
	end

	Rectangle.new(w,h).each do |x,y|
		color = draw_code.call(x,y)
		g.set_pixel x,y,color
	end

	if label
		g.setColor(Color.new 0,0,0)
		g.setFont(Java::JavaAwt::Font.new("Times New Roman", Java::JavaAwt::Font::BOLD, 12))
		g.drawString(label,2,h+18)
	end

	ImageIO::write(image, "png", java.io.File.new(outputfile))
	log "Image #{outputfile} generated"
end

end