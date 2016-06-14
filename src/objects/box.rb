require_relative 'world_object'
require_relative '../libs/algebra'
require_relative 'plane'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
require_relative 'texture'

module Alex
  module Objects
    class Box < WorldObject
      attr_accessor :point, :front, :up, :width_front, :width_up, :width_left
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate
      attr_accessor :texture_file_path, :texture_horizontal_scale, :texture_vertical_scale
      attr_reader :texture
      def initialize(h)
        super(h)
        if self.texture_file_path
          init_texture(self.texture_file_path)
        end
        @planes = []

        # up
        up_plane = Plane.create_from_scratch
        up_plane.front = self.up
        up_plane.up = self.front
        up_plane.point = self.point + self.up * self.width_up

        bottom_plane = Plane.create_from_scratch
        bottom_plane.front = -self.up
        bottom_plane.up = self.front
        bottom_plane.point = self.point - self.up * self.width_up

        # front
        front_plane = Plane.create_from_scratch
        front_plane.front = self.front
        front_plane.up = self.up
        front_plane.point = self.point + self.front * self.width_front
        back_plane = Plane.create_from_scratch
        back_plane.front = -self.front
        back_plane.up = self.up
        back_plane.point = self.point - self.front * self.width_front

        # left
        left = self.front.cross(self.up).normalize
        left_plane = Plane.create_from_scratch
        left_plane.front = left
        left_plane.up = self.up
        left_plane.point = self.point + left * self.width_left
        right_plane = Plane.create_from_scratch
        right_plane.front = -left
        right_plane.up = self.up
        right_plane.point = self.point - left * self.width_left

        @planes << up_plane
        @planes << bottom_plane
        @planes << front_plane
        @planes << back_plane
        @planes << left_plane
        @planes << right_plane
        @plane_widths = [width_up, width_up, width_front, width_front, width_left, width_left]
        @planes.each { |p| p.reinit }
      end

      def init_texture(file_path)
        @texture = Alex::Texture.new(file_path, self.texture_horizontal_scale, self.texture_vertical_scale)
      end

      def cover_area(light_position, light_radius, target_position)
        0
      end

      def intersect(ray)
        @planes.each_with_index do |plane, index|
          intersection, direction, delta = plane.intersect(ray)
          if intersection
            data = { index: index }
            return intersection, direction, delta, data
          end
        end
        nil
      end

      # 根据球和射线的交点获取 法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction, delta, data = nil)
        raise unless data
        index = data[:index]
        plane = @planes[index]
        plane.intersect_parameters(ray, intersection, direction, delta)
      end

      def inner?(position)
        @planes.map { |x| x.inner?(position) }.reduce(true, &:&)
      end

      def surface?(position)
        @planes.map { |x| x.surface?(position) }.reduce(false, &:|)
      end
    end
  end
end