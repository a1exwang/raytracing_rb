require_relative './sphere'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix

module Alex
  module Objects
    class WorldObject
      attr_accessor :reflective, :refractive
      attr_accessor :refractive_attenuation, :reflective_attenuation, :diffuse_rate
      attr_accessor :texture

      def initialize(hash)
        hash.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
        end
      end

      # 根据入射反射法线, 获得反射光线的衰减率
      def reflect_attenuation(ray, intersection, n, reflect)
        k = 1 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.reflective_attenuation * k).to_a
        Vec3.from_a(r, g, b)
      end

      def refraction_attenuation(ray, intersection, n, refract)
        k = 1 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.refractive_attenuation * k).to_a
        Vec3.from_a(r, g, b)
      end

      def reflect_refract_matrix(ray, intersection, n, reflect, refract)
        return nil unless reflect
        i = Math.acos(ray.front.cos(-n))
        if refract
          k = 0.5 + 0.5 * Math.sin(i)
          if k > 1
            k = 1.0
          end
          kr = Math.sqrt(1 - k * k)
        else
          k = 1.0
          kr = 0.0
        end

        [
            Vec3.from_a(k, k, k),
            Vec3.from_a(kr, kr, kr)
        ]
      end

      def diffuse(light_color, position)
        light_color
      end

      private
      def get_reflection_by_ray_and_n(ray, n, intersection)
        cos_theta = -ray.front.cos(n)
        if cos_theta == -1
          Ray.new(ray.front, intersection + ray.front * Alex::EPSILON)
        else
          front = (n * (2 * cos_theta * ray.front.r) + ray.front).normalize
          Ray.new(front, intersection + front * Alex::EPSILON)
        end

      end

      def get_refraction_by_ray_and_n(ray, n, intersection, reflection, refraction_rate)
        sin_i = Math.sqrt(1 - ray.front.cos(n)**2)

        sin_theta = sin_i / refraction_rate
        return nil if sin_theta >= 1
        theta = Math.asin(sin_theta)
        refraction_direction = (n * (ray.front.dot(n) - Math.cos(theta)) / refraction_rate - ray.front / refraction_rate).normalize
        Ray.new(refraction_direction, intersection + refraction_direction * Alex::EPSILON)
      end
    end
  end
end