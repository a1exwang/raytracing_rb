require_relative 'ray_tracer'
require_relative 'libs/algebra'
require_relative 'configurable_object'
require_relative 'fork_jobs'
require 'png'
require 'matrix'
require 'yaml'

module Alex

  class Camera < ConfigurableObject
    # up is z-axis, front is x-axis, left is y-axis
    attr_accessor :position, :up, :front
    attr_accessor :width, :height

    attr_accessor :image_distance, :focal_distance, :aperture_radius
    attr_accessor :retina_width, :retina_height
    attr_accessor :trace_depth

    THREAD_COUNT = 4

    def initialize(world, config_file)
      @width = 0
      @height = 0

      super(config_file)
      @world = world
      @ray_tracer = RayTracer.new(world, self.trace_depth, @width, @height)
    end

    def render_line_parallel(file_name)
      #canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)

      pixels = Array.new(@width) { |i| Array.new(@height) }

      j = 0
      j_lock = Mutex.new
      queue = Queue.new
      threads = Array.new(THREAD_COUNT) do |i|
        Thread.new do
          loop do
            x = queue.deq
            break if x == -1

            @height.times do |y|
              ray = lens_func(x, y)
              color_vec = @ray_tracer.trace_sync(x, y, ray)
              #puts "#{x}, #{y} #{color_vec}" if x == 40
              pixels[x][y] = color_vec
            end

            j_lock.synchronize do
              j += @height
              puts "Progress: #{(j.to_f / @width / @height * 100).round(2)}%" if j % @width == 0
            end
          end
        end
      end

      @width.times do |x|
        queue.enq x
      end
      THREAD_COUNT.times { |i| queue.enq -1 }

      threads.each { |t| t.join }

      puts pixels
      # png = PNG.new canvas
      # png.save file_name
    end

    def render_fork(file_name)
      parent_work = lambda do
        canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)
        4.times do |i|
          data = Marshal.load(File.read("out/file_#{i}"))
          data.each do |x, v|
            v.each do |y, color|
              canvas.point(x, y, vector_to_color(color))
            end
          end
        end
        png = PNG.new canvas
        png.save file_name
      end
      child_work = lambda do |i|
        start_x, end_x = 0, @width
        start_y, end_y = (i / 4.0 * @height).to_i, ((i+1) / 4.0 * @height).to_i

        data = {}
        (start_x...end_x).each do |x|
          data[x] = {}
          (start_y...end_y).each do |y|
            ray = lens_func(x, y)
            color_vec = Vector[0, 0, 0]
            sample_times = 10
            sample_times.times do
              color_vec += @ray_tracer.trace_sync(x, y, ray)
            end
            data[x][y] = color_vec / sample_times
          end
        end
        File.write("out/file_#{i}", Marshal.dump(data))
      end

      fork_jobs(4, parent_work, &child_work)
    end

    def render_sync(file_name)
      canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)

      i = 0
      @width.times do |x|
        @height.times do |y|
          ray = lens_func(x, y)
          color_vec = Vector[0, 0, 0]
          sample_times = 10
          sample_times.times do
            color_vec += @ray_tracer.trace_sync(x, y, ray)
          end
          canvas.point(x, y, vector_to_color(color_vec / sample_times))
          i += 1
        end
        puts "Progress: #{(i.to_f / @width / @height * 100).round(2)}%" if i % 100 == 0
      end

      png = PNG.new canvas
      png.save file_name
    end

    private
    def lens_func2(x, y)
      eye = self.position - self.front * self.image_distance
      left = (self.up.cross(self.front)).normalize
      screen_pos =
          self.position +
              2 * (0.5 - x.to_f / self.width) * self.retina_width * left +
              2 * (y.to_f / self.height - 0.5) * self.retina_height * self.up.normalize
      Ray.new(screen_pos - eye, screen_pos)
    end

    def intersect_plane(ray, point, front)
      # 算出直线和平面的交点
      t = (point - ray.position).dot(front) / (front.dot(ray.front))
      ray.position + ray.front * t
    end

    def lens_func(x, y)
      left = (self.up.cross(self.front)).normalize
      retina_center = self.position - self.front.normalize * self.image_distance
      retina_position = retina_center +
          2 * (x.to_f / self.width - 0.5) * self.retina_width * left +
          2 * (0.5 - y.to_f / self.height) * self.retina_height * self.up.normalize
      theta = rand
      rand_vector = (left.normalize * Math.cos(theta) + self.up.normalize * Math.sin(theta)) * self.aperture_radius
      aperture_position = self.position + rand_vector
      # direction = aperture_position - retina_position

      object_distance = self.focal_distance*self.focal_distance / self.image_distance

      # calculate focal plane
      point_on_focal_plane = self.position + object_distance * self.front.normalize
      normal_vector_focal_plane = self.front

      # get the intersection of focal plane and this ray
      r = Ray.new(self.position - retina_position, retina_position)
      target_point = intersect_plane(r, point_on_focal_plane, normal_vector_focal_plane)

      Ray.new(target_point - aperture_position, aperture_position)
    end

    def vector_to_color(vec)
      raise 'color vector not 3-dimension' unless vec.size == 3
      PNG::Color.new *(vec*255)
    end
  end
end
