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
      @world_objects.each do |obj|
        intersection, direction = obj.intersect(ray)
        if intersection
          new_dis = ray.distance(intersection)
          if new_dis < nearest_dis
            nearest_dis = new_dis
            nearest_obj = obj
            nearest_intersection = intersection
            nearest_direction = direction
          end
        end
      end
      [nearest_obj, nearest_intersection, nearest_direction]
    end

    # 两点之间是否有物体
    def can_go_through?(start, pos, object)
      ray = Alex::Ray.new(start - pos, pos)
      @world_objects.each do |obj|
        intersection, direction = obj.intersect(ray)
        # make sure the intersection is between start and pos
        if intersection && (start - intersection).dot(pos - intersection) < 0
          return false
        end
      end
      true
    end

    # 获得对某点的diffusion有贡献的所有光源
    def diffused_lights(position, object)
      ret = []
      @lights.each do |light|
        if can_go_through?(position, light.position, object)
          ret << [light, light.color]
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
            can_go_through?(ray.position, light.position, object)
          ret << [light, light.color * light.high_light_rate.to_f]
        end
      end
      ret
    end
  end
end