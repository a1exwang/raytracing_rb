require_relative 'configurable_object'

require_relative 'objects/sphere'
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
      @world_objects.each do |obj|
        intersection = obj.intersect(ray)
        if intersection
          new_dis = ray.distance(intersection)
          if new_dis < nearest_dis
            nearest_dis = new_dis
            nearest_obj = obj
            nearest_intersection = intersection
          end
        end
      end
      [nearest_obj, nearest_intersection]
    end

    # 两点之间是否有物体
    def can_go_through?(start, pos, object)
      obj, inter = intersect(Ray.new(pos - start, start))
      obj == nil || obj ==  object
    end

    # 获得对某点的diffusion有贡献的所有光源
    def diffused_lights(position, object)
      ret = []
      @lights.each do |light|
        if can_go_through?(position, light.position, object)
          ret << [light, light.color * light.diffusion_rate]
        end
      end
      ret
    end

    # 对某条光线会产生高光的光源
    def high_lights(ray, object)
      ret = []
      @lights.each do |light|
        ang = ray.front.angle_with(ray.position - light.position)
        #puts "angle: #{ang}"
        if ang < (light.high_light_angle / 180.0 * Math::PI) &&
            can_go_through?(ray.position, light.position, object)
          ret << [light, light.color * light.high_light_rate]
        end
      end
      ret
    end

  end
end