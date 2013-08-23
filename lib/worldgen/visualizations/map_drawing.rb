module WorldGen

java_import java.applet.Applet
java_import java.awt.font.FontRenderContext
java_import java.awt.geom.Rectangle2D
java_import java.net.URL
java_import javax.imageio.ImageIO
java_import javax.swing.JFrame
java_import java.awt.Dimension
java_import javax.swing.JPanel
java_import java.awt.Color

def zoom(level,&original)
	Proc.new do |x,y|
		original.call(x/level,y/level)
	end
end

def shadow_color(altitude,color,x,y)
	alt = altitude[y][x]
	delta = 0
	for dist in 0..4
		if x>dist and y >dist
			other = altitude[y-1-dist][x-1-dist]
			diff = other-alt
			delta+=diff/(1+dist) if other>alt	
		end
	end
	delta = 300 if delta>300
	p = delta.to_f/300.to_f
	p=0 if alt<0
	rescolor = mix_color(Color.new(0,0,0),color,p)
	rescolor
end

class MyPanel < JPanel

	def initialize(w,h,draw_perpixel_block,draw_percycle_block)
		super()
		@w = w
		@h = h
		@draw_block = draw_perpixel_block
		@draw_percycle_block = draw_percycle_block
	end

	def paintComponent(g)
		super g

		class << g
			def set_pixel x,y,color
				self.color = color
				self.draw_line x,y,x,y
			end
		end

		for x in 0..(@w-1)
			for y in 0..(@h-1)
				color = @draw_block.call(x,y)
				g.set_pixel x,y,color
			end
		end

		@draw_percycle_block.call(g) if @draw_percycle_block
	end

end

class MapFrame < JFrame

	def initialize(name,w,h,draw_block,draw_percycle_block=nil)
		super(name)
		@w = w
		@h = h
		p = MyPanel.new(w,h,draw_block,draw_percycle_block)
		add(p)
	end

	def launch
		self.resizable = false
		self.size = Dimension.new @w,@h
		self.default_close_operation = JFrame::EXIT_ON_CLOSE
		self.visible = true
	end

end

end