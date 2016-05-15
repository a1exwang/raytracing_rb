require_relative 'world_object'
require_relative '../libs/algebra'
require 'matrix'

module Alex
  module Objects
    class Sphere < WorldObject
      attr_accessor :center, :radius
      attr_accessor :color
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate

      # 球和射线的第一个交点
      def intersect(ray)
        # 算出直线上到球心最近的点
        t = - (ray.position - self.center).dot(ray.front) / ray.front.r ** 2
        v = t * ray.front
        nearest_point = ray.position + v
        direction = nil

        # 检查最近点是否在光线正方向
        return [nil, nil] if v.dot(ray.front) < 0

        # 如果最近点在球内, 则有交点
        nearest_dis = (nearest_point - self.center).r
        intersection = nil
        if nearest_dis > self.radius
          intersection = nil
        elsif nearest_dis == self.radius
          intersection = nearest_point
        else
          nearest_point_to_intersection = Math.sqrt(self.radius ** 2 - nearest_dis ** 2)
          intersection = nearest_point -
              nearest_point_to_intersection * ray.front.normalize
        end

        # 检查交点的方向
        if intersection
          direction = (intersection - self.center).dot(ray.front) < 0 ? :in : :out
        end

        [intersection, direction]
      end

      # 根据球和射线的交点获取 法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction)
        n = intersection - self.center
        reflection = get_reflection_by_ray_and_n(ray, n, intersection)
        refraction = get_refraction_by_ray_and_n(ray, n, intersection, reflection.front,
                                                 direction == :in ? self.refractive_rate : 1 / self.refractive_rate)

        {
            n: n,
            reflection: reflection,
            refraction: refraction
        }
      end

      def inner?(position)
        (position - self.position).r <= self.radius
      end

      def surface?(position)
        ((position - self.position).r - self.radius) < Alex::EPSILON
      end


    end
  end
end