module Alex::Lights
  class Light
    attr_accessor :position, :name, :color, :diffusion_rate
    attr_accessor :high_light_rate, :high_light_angle

    def initialize(hash)
      hash.each do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end

  end
end