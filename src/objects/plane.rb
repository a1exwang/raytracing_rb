require_relative 'world_object'
require_relative '../libs/algebra'
require 'matrix'

module Alex
  module Objects
    class Plane < WorldObject
      attr_accessor :point, :front
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate
      attr_accessor :texture
      def initialize(h)
        super(h)
      end

      def intersect(ray)
        # 算出直线和平面的交点
        t = (self.point - ray.position).dot(self.front) / (self.front.dot(ray.front))
        intersection = ray.position + ray.front * t

        # 检查交点是否在光线正方向
        return [nil, nil] if t < 0

        # 检查交点的方向
        direction = (self.front).dot(ray.front) < 0 ? :in : :out
        [intersection, direction]
      end

      # 根据球和射线的交点获取 法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction)
        n = self.front
        if n.dot(ray.front) > 0
          n = -n
        end
        #
        # reflection =  get_reflection_by_ray_and_n(ray, n, intersection)
        {
            n: n,
            reflection: nil,
            refraction: nil
        }
      end

      def inner?(position)
        (position - self.point).dot(self.front) > 0
      end

      def surface?(position)
        position == self.point || (position - self.point).normalize.dot(self.front.normalize).abs < Alex::EPSILON
      end

      def diffuse(color, position)
        k = 1
        if self.texture == 'grids'
          i = position[0].to_i
          j = position[1].to_i
          # puts "Z: #{position[2]}"
          k = (i + j) % 2 == 0 ? 1 : 0.3
          # puts "grid diffusion: i, j: #{i}, #{j}"
        end

        Vector[
          color[0] * self.diffuse_rate[0] * k,
          color[1] * self.diffuse_rate[1] * k,
          color[2] * self.diffuse_rate[2] * k
        ]
      end

      # def reflect_refract_matrix(ray, intersection, n, reflect, refract)
      #   return nil unless reflect
      #
      #   i = intersection[0].to_i
      #   j = intersection[1].to_i
      #   k = (i + j) % 2 == 0 ? 1 : 0
      #
      #   [
      #       Matrix[[k, 0, 0], [0, k, 0], [0, 0, k]],
      #       Matrix.zero(3, 3)
      #   ]
      # end
    end
  end
end