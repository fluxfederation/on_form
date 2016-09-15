module OnForm
  module Attributes
    # the individual attribute methods are introduced by the expose_attribute class method.
    # here we introduce some methods used for the attribute set as a whole.

    def [](attribute_name)
      send(attribute_name)
    end

    def []=(attribute_name, attribute_value)
      send("#{attribute_name}=", attribute_value)
    end

    def attribute_names
      self.class.exposed_attributes.values.reduce(:+).collect(&:to_s)
    end

    def attributes
      attribute_names.each_with_object({}) do |attribute_name, results|
        results[attribute_name] = self[attribute_name]
      end
    end

    def attributes=(attributes)
      attributes.each do |attribute_name, attribute_value|
        self[attribute_name] = attribute_value
      end
    end

    def read_attribute_for_validation(attribute_name)
      send(attribute_name)
    end

  private
    def backing_model(backing_model_name)
      send(backing_model_name)
    end

    def backing_models
      self.class.exposed_attributes.keys.collect { |backing_model_name| backing_model(backing_model_name) }
    end
  end
end
