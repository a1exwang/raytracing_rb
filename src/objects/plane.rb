require_relative 'world_object'
require_relative '../libs/algebra'
require 'matrix'

module Alex
  module Objects
    class Plane < WorldObject
      attr_accessor :point, :front
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate
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

      def diffuse(color)
        Vector[
          color[0] * self.diffuse_rate[0],
          color[1] * self.diffuse_rate[1],
          color[2] * self.diffuse_rate[2]
        ]
      end
    end
  end
end