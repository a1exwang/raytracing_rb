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
      attr_accessor :texture_file_path, :texture_horizontal_scale, :texture_vertical_scale, :north_pole_vec, :greenwich_vec
      attr_accessor :texture_u_offset, :texture_v_offset
      attr_reader :texture, :ninety_degree_east_vec

      def initialize(*params)
        super(*params)
        if self.texture_file_path
          @ninety_degree_east_vec = self.north_pole_vec.cross(self.greenwich_vec)
          init_texture(self.texture_file_path)
        end
      end

      def init_texture(file_path)
        @texture = Alex::Texture.new(file_path, self.texture_horizontal_scale, self.texture_vertical_scale, self.texture_u_offset, self.texture_v_offset)
      end

      # def cover_area(light_position, light_radius, target_position)
      #   # 解出包含球心的平面上, 并且在锥面中线上的点x1
      #   t = (self.center - target_position).dot(light_position - target_position) / (light_position - target_position).r2
      #   x1 = target_position + (light_position - target_position) * t
      #   r1 = light_radius * ((x1 - target_position).r / (light_position - target_position).r)
      #
      #   # 判断两圆的位置关系
      #   d = (x1 - center).r
      #   if d >= r1 + self.radius
      #     0
      #   else
      #     s1 = Math::PI * r1 * r1
      #     if d > (self.radius - r1).abs
      #       cos_theta1 = [(r1 * r1 + d * d - self.radius * self.radius) / (2 * r1 * d), 1.0].min
      #       cos_theta2 = [(self.radius * self.radius + d * d - r1 * r1) / (2 * self.radius * d), 1.0].min
      #       theta1 = Math.acos(cos_theta1)
      #       theta2 = Math.acos(cos_theta2)
      #       delta_s = ((theta1 - Math.sin(theta1)) * r1 * r1 + (theta2 - Math.sin(theta2)) * self.radius * self.radius) / 2
      #       delta_s / s1
      #     else
      #       if r1 > self.radius
      #         Math::PI * self.radius * self.radius / s1
      #       else
      #         1
      #       end
      #     end
      #   end
      # end

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

        from_inner = inner?(ray.position)
        direction = from_inner ? :out : :in

        intersection = direction == :in ? nearest_point - vec : nearest_point + vec

        # 球内发出的光线一定和球内壁有交点
        if !from_inner && t < 0
          return nil
        end

        [intersection, direction, (intersection - self.center) * Alex::EPSILON * (direction == :in ? 1.0 : -1.0)]
      end

      # 根据球和射线的交点获取法向量, 反射光线, 折射光线
      def intersect_parameters(ray, intersection, direction, delta, data = nil)
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

      def get_uv(position)
        vec = position - self.center
        x = vec.dot(self.greenwich_vec.normalize) / self.radius
        y = vec.dot(@ninety_degree_east_vec.normalize) / self.radius
        z = vec.dot(self.north_pole_vec.normalize) / self.radius
        m = Math.sqrt(x*x+y*y+z*z + 2*x + 1)
        u = (y / m + 1) / 2
        v = (-z / m + 1) / 2
        [u, v]
      end

      def local_lighting(position, light_position, normal_vector, ray, color_filter = Vec3.from_a(1.0, 1.0, 1.0))
        if self.texture
          u, v = get_uv(position)
          super(position, light_position, normal_vector, ray, self.texture.color(u, v) * color_filter)
        else
          super
        end
      end
    end
  end
end