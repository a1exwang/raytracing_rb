require_relative './sphere'

module Alex
  module Objects
    class WorldObject
      attr_accessor :reflective, :refractive
      attr_accessor :refractive_attenuation, :reflective_attenuation, :diffuse_rate

      def initialize(hash)
        hash.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
        end
      end

      # 根据入射反射法线, 获得反射光线的衰减率
      def reflect_attenuation(ray, intersection, n, reflect)
        k = 1 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.reflective_attenuation * k).to_a
        Matrix[
            [r, 0, 0],
            [0, g, 0],
            [0, 0, b]
        ]
      end

      def refraction_attenuation(ray, intersection, n, refract)
        k = 1 #- ray.front.normalize.dot(n.normalize) ** 2
        r, g, b = (self.refractive_attenuation * k).to_a
        Matrix[
            [r, 0, 0],
            [0, g, 0],
            [0, 0, b]
        ]
      end

      def diffuse(color)
        color
      end

      def reflect_refract_matrix(ray, intersection, n, reflect, refract)
        return nil unless reflect
        i = ray.front.angle_with(-n)
        if refract
          k = 0.5 + 0.5 * Math.sin(i)
          if k > 1
            k = 1
          end
          kr = Math.sqrt(1 - k * k)
        else
          k = 1
          kr = 0
        end

        [
            Matrix[[k, 0, 0], [0, k, 0], [0, 0, k]],
            Matrix[[kr, 0, 0], [0, kr, 0], [0, 0, kr]]
        ]
      end

      private

      def get_reflection_by_ray_and_n(ray, n, intersection)
        cos_theta = ray.front.normalize.dot(n.normalize)
        front = 2 * cos_theta * ray.front.r * n + ray.front
        Ray.new(front, intersection)
      end

      def get_refraction_by_ray_and_n(ray, n, intersection, reflection, refraction_rate)
        sin_i = Math.sqrt(1 - ray.front.normalize.dot((-n).normalize)**2)

        sin_theta = sin_i / refraction_rate
        return nil if sin_theta >= 1
        theta = Math.asin(sin_theta)
        Ray.new((1 / refraction_rate * (ray.front.dot(n) - Math.cos(theta)) * n) - 1 / refraction_rate * ray.front,
            intersection)
      end
    end
  end
end