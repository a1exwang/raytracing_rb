require_relative 'world_object'
require_relative '../libs/algebra'
require 'matrix'

module Alex
  module Objects
    class Sphere < WorldObject
      attr_accessor :center, :radius, :north_pole, :greenwich
      attr_accessor :color
      attr_accessor :name
      attr_accessor :reflective_attenuation, :refractive_attenuation, :refractive_rate
      attr_accessor :texture_file

      def vector_to_texture(vector)
        v1 = vector - north_pole
      end

      def lit_area(light_position, light_radius, target_position)
        # 解出包含球心的平面上, 并且在锥面中线上的点x1
        t = (self.center - target_position).dot(light_position - target_position) / (light_position - target_position).r2
        x1 = target_position + (light_position - target_position) * t
        r1 = light_radius * ((x1 - target_position).r / (light_position - target_position).r)

        # 判断两圆的位置关系
        d = (x1 - center).r
        if d >= r1 + self.radius
          1.0
        else
          s1 = Math::PI * r1 * r1
          if d > self.radius - r1
            theta1 = Math.acos((r1 * r1 + d * d - self.radius * self.radius) / (2 * r1 * d))
            theta2 = Math.acos((self.radius * self.radius + d * d - r1 * r1) / (2 * self.radius * d))
            delta_s = ((theta1 - Math.sin(theta1)) * r1 * r1 + (theta2 - Math.sin(theta2)) * self.radius * self.radius) / 2

            1 - delta_s / s1
          else
            if r1 > self.radius
              1 - Math::PI * self.radius * self.radius / s1
            else
              0
            end
          end
        end
      end

      # 球和射线的第一个交点
      def intersect(ray)
        # 算出直线上到球心最近的点
        t = (self.center - ray.position).dot(ray.front) / ray.front.r2
        v = ray.front * t
        nearest_point = ray.position + v

        # 如果最近点在球内, 则有交点
        unless inner?(nearest_point)
          return nil
        end
        nearest_dis = (nearest_point - self.center).r
        nearest_point_to_intersection = Math.sqrt(self.radius ** 2 - nearest_dis ** 2)
        vec = ray.front.normalize * nearest_point_to_intersection
        # 检查最近点是否在光线正方向

        intersection = nearest_point + vec
        direction = nil

        # 球内发出的光线一定和球内壁有交点
        if inner?(ray.position)
          direction = :out
        else # inner?(ray.position) == false
          if t >= 0
            direction = :in
          else
            return nil
          end
        end

        [intersection, direction, (intersection - self.center) * Alex::EPSILON * (direction == :in ? 1.0 : -1.0)]
      end

      # 根据球和射线的交点获取 法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction, delta)
        n = direction == :in ? (intersection - self.center) : (self.center - intersection)
        reflection = get_reflection_by_ray_and_n(ray, n, intersection, delta)
        refraction = get_refraction_by_ray_and_n(ray, n, intersection,
                                                 reflection.front,
                                                 direction == :in ? self.refractive_rate : 1.0 / self.refractive_rate,
                                                 delta)

        {
            n: n,
            reflection: reflection,
            refraction: refraction
        }
      end

      def inner?(position)
        (position - self.center).r <= self.radius
      end

      def surface?(position)
        ((position - self.center).r - self.radius) < Alex::EPSILON
      end
    end
  end
end