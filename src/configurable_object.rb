module Alex

  class ConfigurableObject
    def initialize(config_file)
      parse_config_file(config_file)
    end

    def array_parse_vector(array)
      new_array = []
      array.each do |value|
        if value.is_a?(Hash)
          new_array << hash_value_parse_vector(value)
        elsif value.is_a?(Array) && value.size == 3 && (value.reject { |x| x.is_a? Numeric }).size == 0
          # Array of three numeric elements
          new_array << Vector[*value]
        elsif value.is_a?(Array)
          new_array << array_parse_vector(value)
        end
      end
      new_array
    end

    def hash_value_parse_vector(hash)
      new_hash = {}
      hash.each do |key, value|
        if value.is_a?(Hash)
          new_hash[key.to_sym] = hash_value_parse_vector(value)
        elsif value.is_a?(Array) && value.size == 3 && (value.reject { |x| x.is_a? Numeric }).size == 0
          # Array of three numeric elements
          new_hash[key.to_sym] = Vector[*value]
        elsif value.is_a?(Array)
          new_hash[key.to_sym] = array_parse_vector(value)
        else
          new_hash[key.to_sym] = value
        end
      end
      new_hash
    end

    def parse_config_file(file)
      config = YAML.load(File.read(file))
      config = hash_value_parse_vector(config)
      config.each do |key, value|
        instance_variable_set('@' + key.to_s, value)
      end
    end
  end
end