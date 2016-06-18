require_relative './sphere'
require_relative '../../lib/fast_4d_matrix/fast_4d_matrix'
include Fast4DMatrix

module Alex
  module Objects
    class WorldObject
      attr_accessor :reflective, :refractive
      attr_accessor :refractive_attenuation, :reflective_attenuation, :diffuse_rate, :ambient
      attr_accessor :texture

      attr_accessor :reflect_probability, :refract_probability, :diffuse_probability

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

      def cover_area(light_position, light_radius, target_position)
        ray = Alex::Ray.new(light_position - target_position, target_position)
        intersection, *_ = intersect(ray)
        if intersection && (intersection - light_position).dot(target_position - light_position) > 0
          1
        else
          0
        end
      end

      def local_lighting(position, lights, normal_vector, ray, color_filter = nil)
        light_contribution = Vec3.from_a(0.0, 0.0, 0.0)
        lights.each do |light, light_color|
          n = normal_vector.normalize
          l = (light.position - position).normalize
          l_dot_n = l.dot(n)
          if l_dot_n > 1
            l_dot_n = 1.0
          elsif l_dot_n < 0
            l_dot_n = 0.0
          else
            # l_dot_n = Math.sqrt l_dot_n
          end
          light_contribution += light_color * l_dot_n
        end
        if lights.size > 0
          light_contribution /= lights.size.to_f
        end
        if color_filter
          light_contribution * self.diffuse_rate * color_filter + self.ambient
        else
          light_contribution * self.diffuse_rate + self.ambient
        end
      end

      def path_tracing(intersection, n, pt_times)
        ret = []
        att = self.diffuse_rate / pt_times.to_f
        pt_times.times do
          front = n.normalize
          left = get_a_random_vertical_vector(n).normalize
          up = front.cross(left)
          # theta是俯仰角(0-90度, 只取夹角和n小于90度的向量), phi是方位角,
          theta, phi = Random.rand * Math::PI / 2, Random.rand * Math::PI * 2
          direction = front * Math.sin(theta) + (left * Math.cos(phi) + up * Math.sin(phi)) * Math.cos(theta)
          ray = Alex::Ray.new(direction, intersection)
          ret << [ray, att]
        end
        ret
      end

      def diffuse_ray(intersection, n)
        att = self.diffuse_rate
        front = n.normalize
        left = get_a_random_vertical_vector(n).normalize
        up = front.cross(left)
        # theta是俯仰角(0-90度, 只取夹角和n小于90度的向量), phi是方位角,
        theta, phi = Random.rand * Math::PI / 2, Random.rand * Math::PI * 2
        direction = front * Math.sin(theta) + (left * Math.cos(phi) + up * Math.sin(phi)) * Math.cos(theta)
        ray = Alex::Ray.new(direction, intersection)
        [ray, att]
      end

      private
      def get_a_random_vertical_vector(n)
        raise 'zero vector detected' if n.r == 0
        a = n.to_a
        if a[0] == 0
          if a[1] == 0
            # x = 0 and y = 0, z != 0
            Vec3.from_a(1.0, 0.0, 0.0)
          else
            # x = 0 but y != 0
            Vec3.from_a(0.0, -a[2]/a[1], 1.0)
          end
        else
          # x != 0
          Vec3.from_a(-(a[1]+a[2]) / a[0], 1.0, 1.0)
        end
      end
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