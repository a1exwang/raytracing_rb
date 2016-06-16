require_relative 'world_object'
require_relative '../libs/algebra'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
require_relative 'texture'

module Alex
  module Objects
    class Plane < WorldObject
      attr_accessor :point, :front, :up
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate
      attr_accessor :texture_file_path, :texture_horizontal_scale, :texture_vertical_scale
      attr_reader :texture
      attr_reader :left
      attr_accessor :u_unit, :v_unit

      def self.create_from_scratch
        self.new
      end

      def reinit
        @left = self.front.cross(self.up).normalize
      end

      def initialize(h = nil)
        return unless h
        super(h)
        if self.texture_file_path
          init_texture(self.texture_file_path)
        end
        reinit
      end

      def init_texture(file_path)
        @texture = Alex::Texture.new(file_path, self.texture_horizontal_scale, self.texture_vertical_scale)
      end

      def cover_area(light_position, light_radius, target_position)
        0
      end

      def intersect(ray)
        # 算出直线和平面的交点
        denominator = self.front.dot(ray.front)
        return nil if denominator == 0
        t = (self.point - ray.position).dot(self.front) / denominator
        intersection = ray.position + ray.front * t

        # 检查交点是否在光线正方向
        return [nil, nil] if t < 0

        # 检查交点的方向
        direction = self.front.dot(ray.front) < 0 ? :in : :out
        [intersection, direction, self.front * Alex::EPSILON * (-self.front.dot(ray.front) <=> 0).to_f]
      end

      # 根据球和射线的交点获取 法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction, delta, data = nil)
        n = self.front.dot(ray.front) > 0 ? -self.front : self.front
        reflection = get_reflection_by_ray_and_n(ray, n, intersection, delta)
        if self.refractive_rate
          refraction = get_refraction_by_ray_and_n(ray, n, intersection, reflection.front, self.refractive_rate, delta)
        else
          refraction = nil
        end
          {
            n: n,
            reflection: reflection,
            refraction: refraction
          }
      end

      def inner?(position)
        (position - self.point).dot(self.front) > 0
      end

      def surface?(position)
        return true if position == self.point
        a = position - self.point
        a.cos(self.front) < Alex::EPSILON
      end

      # u: left
      # v: up
      def get_uv(position)
        u = (position - self.point).dot(self.left.normalize) / self.u_unit
        v = (position - self.point).dot(self.up.normalize) / self.v_unit
        [u, v]
      end

      def local_lighting(color, position, light_position, normal_vector, ray)
        if self.texture
          u, v = get_uv(position)
          super(color * self.texture.color(u, v), position, light_position, normal_vector, ray)
        else
          super
        end
      end
    end
  end
end