module WorldGen

require 'grap/tiles'
require 'grap/colors'
require 'grap/map_drawing'

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

def save_image(w,h,outputfile,&draw_code)
	image = BufferedImage.new(w,h, BufferedImage::TYPE_INT_ARGB)
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

	ImageIO::write(image, "png", java.io.File.new(outputfile))
end

end