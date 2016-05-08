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
    def initialize(world, config_file)
      @width = 0
      @height = 0

      super(config_file)
      @world = world
      @ray_tracer = RayTracer.new(world, 5)
    end

    def render(file_name)
      canvas = PNG::Canvas.new(@width, @height)

      @width.times do |x|
        @height.times do |y|
          #puts "rendering #{x}, #{y}"
          ray = lens_func(x, y)
          color_vec = @ray_tracer.trace(x, y, ray)
          canvas.point(x, y, vector_to_color(color_vec))
        end
      end

      png = PNG.new canvas
      png.save file_name
    end

    private
    def lens_func(x, y)
      eye = self.position + self.front * self.image_distance
      screen_pos =
          self.position +
              (x.to_f / self.width - 0.5) * self.viewport_width * self.up.normalize +
              (y.to_f / self.height - 0.5) * self.viewport_height * (self.up.cross(self.front)).normalize
      Ray.new(screen_pos - eye, screen_pos)
    end

    def vector_to_color(vec)
      raise 'color vector not 3-dimension' unless vec.size == 3
      PNG::Color.new *(vec*255)
    end
  end
end
