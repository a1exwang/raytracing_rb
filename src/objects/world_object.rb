require_relative './sphere'

module Alex
  module Objects
    class WorldObject
      def initialize(hash)
        hash.each do |key, value|
          instance_variable_set('@' + key.to_s, value)
        end
      end
    end
  end
end