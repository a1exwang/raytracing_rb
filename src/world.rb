require_relative 'configurable_object'
require_relative 'objects/sphere'
module Alex
  class World < ConfigurableObject
    attr_accessor :ambient_light
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
  end
end