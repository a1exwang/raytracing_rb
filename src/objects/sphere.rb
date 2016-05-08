require_relative 'world_object'

module Alex
  module Objects
    class Sphere < WorldObject
      attr_accessor :center, :radius
      attr_accessor :color
    end
  end
end