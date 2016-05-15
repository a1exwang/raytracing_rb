require_relative 'ray_tracer'
require_relative 'libs/algebra'
require_relative 'configurable_object'
require 'png'
require 'matrix'
require 'yaml'

module Alex

  class Camera < ConfigurableObject
    # up is z-axis, front is x-axis, left is y-axis
    attr_accessor :position, :up, :front
    attr_accessor :width, :height

    attr_accessor :image_distance
    attr_accessor :viewport_width, :viewport_height
    attr_accessor :trace_depth
    def initialize(world, config_file)
      @width = 0
      @height = 0

      super(config_file)
      @world = world
      @ray_tracer = RayTracer.new(world, self.trace_depth, @width, @height)
    end

    def render_sync(file_name)
      canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)

      i = 0
      @width.times do |x|
        @height.times do |y|
          ray = lens_func(x, y)
          color_vec = @ray_tracer.trace_sync(x, y, ray)
          #puts "#{x}, #{y} #{color_vec}" if x == 40
          canvas.point(x, y, vector_to_color(color_vec))
          i += 1
        end
        puts "Progress: #{(i.to_f / @width / @height * 100).round(2)}%" if i % 400 == 0
      end

      png = PNG.new canvas
      png.save file_name
    end

    def render(file_name)
      canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)

      i = 0
      @width.times do |x|
        @height.times do |y|
          ray = lens_func(x, y)
          @ray_tracer.trace(x, y, ray)
          i += 1
        end
        puts "Progress: #{(i.to_f / @width / @height * 100).round(2)}%" if i % 400 == 0
      end
      sleep 1000
      #canvas.point(x, y, vector_to_color(color_vec))

      png = PNG.new canvas
      png.save file_name
    end

    private
    def lens_func(x, y)
      eye = self.position - self.front * self.image_distance
      left = (self.up.cross(self.front)).normalize
      screen_pos =
          self.position +
              2 * (0.5 - x.to_f / self.width) * self.viewport_width * left +
              2 * (y.to_f / self.height - 0.5) * self.viewport_height * self.up.normalize
      Ray.new(screen_pos - eye, screen_pos)
    end

    def vector_to_color(vec)
      raise 'color vector not 3-dimension' unless vec.size == 3
      PNG::Color.new *(vec*255)
    end
  end
end
