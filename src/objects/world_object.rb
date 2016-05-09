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

      # def intersect(ray)
      #   puts 'world object intersect'
      #   nil
      # end

      private

      def get_reflection_by_ray_and_n(ray, n, intersection)
        cos_theta = ray.front.normalize.dot(n.normalize)
        front = 2 * cos_theta * ray.front.r * n + ray.front
        Ray.new(front, intersection)
      end
    end
  end
end