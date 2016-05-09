require_relative './sphere'

module Alex
  module Objects
    class WorldObject
      attr_accessor :reflective, :refractive

      def initialize(hash)
        hash.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
        end
      end

      def intersect(ray)
        nil
      end

      private

      def get_reflection_by_ray_and_n(ray, n)
        cos_theta = ray.front.normalize.dot(n.normalize)
        front = 2 * cos_theta * ray.front.normalize * n + ray.front
        Ray.new(front, ray.position)
      end
    end
  end
end