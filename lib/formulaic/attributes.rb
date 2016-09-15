module Formulaic
  module Attributes
    def read_attribute_for_validation(attribute_name)
      send(attribute_name)
    end

    def [](attribute_name)
      send(attribute_name)
    end

    def []=(attribute_name, attribute_value)
      send("#{attribute_name}=", attribute_value)
    end

  private
    def backing_model(backing_model_name)
      send(backing_model_name)
    end

    def backing_models
      self.class.exposed_attributes.keys.collect { |backing_model_name| backing_model(backing_model_name) }
    end

    def write_attributes(attributes)
      attributes.each do |attribute_name, attribute_value|
        self[attribute_name] = attribute_value
      end
    end
  end
end
