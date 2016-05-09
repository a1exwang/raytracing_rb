require_relative 'world_object'
require_relative '../libs/algebra'
require 'matrix'

module Alex
  module Objects
    class Sphere < WorldObject
      attr_accessor :center, :radius
      attr_accessor :color
    end

    def intersect(ray)
      # 算出直线上到球心最近的点
      t = - (ray.position - self.center).dot(ray.front) / ray.front.r ** 2
      v = t * ray.front
      nearest_point = ray.position + v

      # 检查最近点是否在光线正方向
      # 这样就禁止了球内向球外发出光线
      if v.dot(ray.front) < 0
        return nil
      end

      # 如果最近点在球内, 则有交点
      nearest_dis = (nearest_point - self.center).r
      if nearest_dis > self.radius
        nil
      elsif nearest_dis == self.radius
        nearest_point
      else
        nearest_point_to_intersection = Math.sqrt(self.radius ** 2 - nearest_dis ** 2)
        nearest_point -
            nearest_point_to_intersection * ray.front.normalize
      end

    end

    def intersect_parameters(ray, intersection)
      n = intersection - self.center
      reflection =  get_reflection_by_ray_and_n(ray, n)

      {
          n: n,
          reflection: reflection
      }
    end

    def reflect_attenuation(ray, intersection, n, reflect)
      Matrix[
        [0.5, 0, 0],
        [0, 0.5, 0],
        [0, 0, 0.5]
      ]
    end

  end
end