require_relative 'ray_tracer'
require_relative 'libs/algebra'
require_relative 'configurable_object'
require_relative 'fork_jobs'
require_relative '../lib/fast_4d_matrix/fast_4d_matrix'
require 'png'
require 'matrix'
require 'yaml'
require 'json'

include Fast4DMatrix

module Alex

  class Camera < ConfigurableObject
    # up is z-axis, front is x-axis, left is y-axis
    attr_accessor :position, :up, :front
    attr_accessor :width, :height

    attr_accessor :image_distance, :focal_distance, :aperture_radius
    attr_accessor :retina_width, :retina_height
    attr_accessor :trace_depth
    attr_accessor :max_sample_times, :pre_sample_times, :variant_threshold

    THREAD_COUNT = 24

    def initialize(world, config_file)
      @width = 0
      @height = 0

      super(config_file)
      @world = world
      @ray_tracer = RayTracer.new(world, self.trace_depth, @width, @height)
    end

    def render_fork(file_name)
      parent_work = lambda do
        canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)
        THREAD_COUNT.times do |i|
          data = JSON.parse(File.read("out/file_#{i}.json"))
          data.each do |x, v|
            v.each do |y, color|
              canvas.point(x, y, vector_to_color(Vec3.from_a(*color)))
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
            color_vec = Vec3.from_a(0.0, 0.0, 0.0)
            sample_times = 1
            sample_times.times do
              color_vec += @ray_tracer.trace_sync(x, y, ray)
            end
            data[x][y] = color_vec / sample_times.to_f
          end
        end
        File.write("out/file_#{i}.json", data.to_json)
      end

      fork_jobs(4, parent_work, &child_work)
    end

    def render_sync(file_name)
      canvas = PNG::Canvas.new(@width, @height, PNG::Color::Black)

      i = 0
      ten_count = 0
      @width.times do |x|
        @height.times do |y|
          pre_samples = []
          average = Vec3.from_a(0.0, 0.0, 0.0)
          Array.new(self.pre_sample_times) do |j|
            ray = lens_func(x, y, j)
            v =  @ray_tracer.trace_sync(x, y, ray)
            pre_samples << v
            average += v
          end

          variance = 0
          average /= self.pre_sample_times.to_f
          self.pre_sample_times.times do |j|
            variance += (pre_samples[j] - average).to_a.max ** 2
          end
          variance /= self.pre_sample_times

          if variance >= self.variant_threshold
            color_vec = Vec3.from_a(0.0, 0.0, 0.0)
            (self.pre_sample_times...self.max_sample_times).each do |j|
              ray = lens_func(x, y, j)
              color_vec += @ray_tracer.trace_sync(x, y, ray)
            end
            ten_count += 1
            average = (average * self.pre_sample_times.to_f + color_vec) / self.max_sample_times.to_f
          else
            average
          end

          canvas.point(x, @height - 1 - y, vector_to_color(average))
          i += 1
        end
        puts "Progress: #{(i.to_f / @width / @height * 100).round(2)}%" if i % 100 == 0
      end

      puts "ten_count: #{ten_count}"

      png = PNG.new canvas
      png.save file_name
    end

    private
    def lens_func1(x, y, i)
      eye = self.position - self.front * self.image_distance
      left = self.up.cross(self.front).normalize
      screen_pos =
          self.position +
              left * (2 * (0.5 - x.to_f / self.width) * self.retina_width)  +
              self.up.normalize * (2 * (0.5 - y.to_f / self.height) * self.retina_height)
      Ray.new(screen_pos - eye, screen_pos)
    end

    def intersect_plane(ray, point, front)
      # 算出直线和平面的交点
      t = (point - ray.position).dot(front).to_f / (front.dot(ray.front))
      ray.position + ray.front * t
    end

    def lens_func(x, y, i)
      left = self.up.cross(self.front).normalize
      retina_center = self.position - self.front.normalize * self.image_distance
      retina_position = retina_center +
          left * (2.0 * (x.to_f / self.width - 0.5) * self.retina_width) +
          self.up.normalize * (2 * (y.to_f / self.height - 0.5) * self.retina_height)
      theta = Random.rand
      rand_vector = (left.normalize * Math.cos(theta) + self.up.normalize * Math.sin(theta)) * self.aperture_radius
      aperture_position = self.position + rand_vector
      # direction = aperture_position - retina_position

      object_distance = self.focal_distance * self.image_distance / (self.image_distance - self.focal_distance)

      # calculate focal plane
      point_on_focal_plane = self.position + (self.front.normalize) * object_distance
      normal_vector_focal_plane = self.front

      # get the intersection of focal plane and this ray
      r = Ray.new(self.position - retina_position, retina_position)
      target_point = intersect_plane(r, point_on_focal_plane, normal_vector_focal_plane)

      Ray.new(target_point - aperture_position, aperture_position)
    end

    def vector_to_color(vec)
      # raise 'color vector not 3-dimension' unless vec.size == 3
      x, y, z = (vec*(1*255.0)).to_a
      PNG::Color.new([x, 255].min, [y, 255].min, [z, 255].min)
    end
  end
end
