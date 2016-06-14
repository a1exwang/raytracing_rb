require_relative 'configurable_object'

require_relative 'objects/sphere'
require_relative 'objects/plane'

require_relative 'lights/spot_light'

module Alex
  class World < ConfigurableObject
    attr_accessor :ambient_light
    attr_accessor :max_distance
    attr_accessor :trace_depth

    def initialize(config_file)
      super(config_file)
      @world_objects  = parse_objects(@world_objects)
      @lights         = parse_lights(@lights)
    end

    def parse_lights(array)
      ret = []
      array.each do |item|
        ret << eval("Alex::Lights::#{item[:type]}Light").new(item[:properties])
      end
      ret
    end
    def parse_objects(array)
      ret = []
      array.each do |item|
        ret << eval("Alex::Objects::#{item[:type]}").new(item[:properties])
      end
      ret
    end

    # 获得第一个和光线相交的物体和交点
    def intersect(ray)
      nearest_obj = nil
      nearest_dis = self.max_distance
      nearest_intersection = nil
      nearest_direction = nil
      nearest_delta = nil
      @world_objects.each do |obj|
        intersection, direction, delta = obj.intersect(ray)
        if intersection
          new_dis = ray.distance(intersection)
          if new_dis < nearest_dis
            nearest_dis = new_dis
            nearest_obj = obj
            nearest_intersection = intersection
            nearest_direction = direction
            nearest_delta = delta
          end
        end
      end
      [nearest_obj, nearest_intersection, nearest_direction, nearest_delta]
    end

    # 获得光源能照到的面积, 只考虑一个遮挡物的情况
    def lit_area(target, light_pos, radius, object)
      # ray = Alex::Ray.new(target - light_pos, light_pos)
      # @world_objects.each do |obj|
      #   intersection, direction = obj.intersect(ray)
      #   # make sure the intersection is between start and pos
      #   if intersection && (target - intersection).dot(light_pos - intersection) < 0
      #     return false
      #   end
      # end
      # true
      ret = 0
      @world_objects.each do |obj|
        if (area = obj.lit_area(light_pos, radius, target)) > 0
          ret += area
        end
      end
      ret
    end

    # 获得对某点的diffusion有贡献的所有光源, 以及光源照到的面积
    def diffused_lights(position, object)
      ret = []
      @lights.each do |light|
        if (area = lit_area(position, light.position, light.radius, object)) > 0
          ret << [light, light.color * area]
        end
      end
      ret
    end

    # 获得某条光线直接射到的光源
    def high_lights(ray, object)
      ret = []
      @lights.each do |light|
        a = light.position - ray.position
        cos_theta = ray.front.cos(a)
        cos_theta = -1 if cos_theta < -1
        cos_theta = 1 if cos_theta > 1
        ang = Math.acos(cos_theta)
        #puts "angle: #{ang}"
        if ang < (light.high_light_angle / 180.0 * Math::PI) &&
            lit_area(ray.position, light.position, light.radius, object)
          ret << [light, light.color * light.high_light_rate.to_f]
        end
      end
      ret
    end
  end
end