require_relative 'configurable_object'
require_relative 'objects/sphere'
module Alex
  class World < ConfigurableObject
    attr_accessor :ambient_light
    attr_accessor :max_distance
    def initialize(config_file)
      super(config_file)
      @world_objects = parse_objects(@world_objects)
    end

    def parse_objects(array)
      ret = []
      array.each do |item|
        ret << eval("Alex::Objects::#{item[:type]}").new(item[:properties])
      end
      ret
    end

    def intersect(ray)
      nearest_obj = nil
      nearest_dis = self.max_distance
      intersection = nil
      @world_objects.each do |obj|
        intersection = obj.intersect(ray)
        if intersection
          new_dis = ray.distance(intersection)
          if new_dis < nearest_dis
            nearest_dis = new_dis
            nearest_obj = obj
          end
        end
      end
      [nearest_obj, intersection]
    end

  end
end