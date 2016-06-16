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

        left = self.front.cross(self.up).normalize
        # up
        up_plane = Plane.create_from_scratch
        up_plane.front = self.up
        up_plane.up = left
        up_plane.point = self.point + self.up * self.width_up * 0.5
        up_plane.u_unit, up_plane.v_unit = [self.width_front, self.width_left]
        bottom_plane = Plane.create_from_scratch
        bottom_plane.front = -self.up
        bottom_plane.up = left
        bottom_plane.point = self.point - self.up * self.width_up * 0.5
        bottom_plane.u_unit, bottom_plane.v_unit = [self.width_front, self.width_left]

        # front
        front_plane = Plane.create_from_scratch
        front_plane.front = self.front
        front_plane.up = self.up
        front_plane.point = self.point + self.front * self.width_front * 0.5
        front_plane.u_unit, front_plane.v_unit = [self.width_left, self.width_up]
        back_plane = Plane.create_from_scratch
        back_plane.front = -self.front
        back_plane.up = self.up
        back_plane.point = self.point - self.front * self.width_front * 0.5
        back_plane.u_unit, back_plane.v_unit = [self.width_left, self.width_up]

        # left
        left = self.front.cross(self.up).normalize
        left_plane = Plane.create_from_scratch
        left_plane.front = left
        left_plane.up = self.up
        left_plane.point = self.point + left * self.width_left * 0.5
        left_plane.u_unit, left_plane.v_unit = [self.width_front, self.width_up]
        right_plane = Plane.create_from_scratch
        right_plane.front = -left
        right_plane.up = self.up
        right_plane.point = self.point - left * self.width_left * 0.5
        right_plane.u_unit, right_plane.v_unit = [self.width_front, self.width_up]

        @planes << up_plane
        @planes << bottom_plane
        @planes << front_plane
        @planes << back_plane
        @planes << left_plane
        @planes << right_plane
        @planes.each do |p|
          p.reflective_attenuation = self.reflective_attenuation
          p.refractive_attenuation = self.refractive_attenuation
          p.refractive_rate = self.refractive_rate
          p.diffuse_rate = self.diffuse_rate
          p.reinit
        end
      end

      def init_texture(file_path)
        @texture = Alex::Texture.new(file_path, self.texture_horizontal_scale, self.texture_vertical_scale)
      end

      def intersect(ray)
        nearest_dis = Float::INFINITY
        nearest_ret = nil
        @planes.each_with_index do |plane, index|
          intersection, direction, delta = plane.intersect(ray)
          if intersection
            u, v = plane.get_uv(intersection)
            if -0.5 <= u && u <= 0.5 && -0.5 <= v && v <= 0.5
              d = (intersection - ray.position).r
              if d < nearest_dis
                nearest_dis = d
                data = { index: index }
                nearest_ret = [intersection, direction, delta, data]
              end
            end
          end
        end
        nearest_ret
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