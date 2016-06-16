require_relative './sphere'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix

module Alex
  module Objects
    class WorldObject
      attr_accessor :reflective, :refractive
      attr_accessor :refractive_attenuation, :reflective_attenuation, :diffuse_rate, :ambient
      attr_accessor :texture

      def initialize(hash)
        hash.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
        end
      end

      # 根据入射反射法线, 获得反射光线的衰减率
      def get_reflect_attenuation(ray, intersection, n, reflect)
        k = 0.9 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.reflective_attenuation * k).to_a
        Vec3.from_a(r, g, b)
      end

      def get_refraction_attenuation(ray, intersection, n, refract)
        k = 0.9 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.refractive_attenuation * k).to_a
        Vec3.from_a(r, g, b)
      end

      def reflect_refract_vector(ray, intersection, n, reflect, refract)
        return nil unless reflect
        # TODO 根据冯模型计算反射和折射强度

        # ray视点到交点的向量
        [self.reflective_attenuation, self.refractive_attenuation]
      end

      def local_lighting(light_color, position, light_position, normal_vector, ray)
        n = normal_vector.normalize
        l = (light_position - position).normalize
        l_dot_n = l.dot(n)
        if l_dot_n > 1
          l_dot_n = 1.0
        elsif l_dot_n < 0
          l_dot_n = 0.0
        end
        light_color *
            (self.diffuse_rate * l_dot_n + self.ambient)
      end

      private
      def get_reflection_by_ray_and_n(ray, n, intersection, delta)
        cos_theta = ray.front.cos(-n)
        front = (n.normalize * (2 * cos_theta * ray.front.r) + ray.front).normalize
        Ray.new(front, intersection + delta)
      end

      def get_refraction_by_ray_and_n(ray, n, intersection, reflection, refraction_rate, delta)
        sin_i = Math.sqrt(1 - ray.front.cos(n)**2)

        sin_r = sin_i / refraction_rate
        return nil if sin_r >= 1 # 全反射, 不发生折射
        r = Math.asin(sin_r)
        # refraction_direction = (n * (ray.front.dot(n) - Math.cos(r)) / refraction_rate - ray.front / refraction_rate).normalize
        refraction_direction =
            (n.normalize * (-Math.cos(r)) + (reflection + ray.front).normalize * sin_r)
        Ray.new(refraction_direction, intersection - n.normalize * Alex::EPSILON)
      end
    end
  end
end