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

    def read_attribute_for_validation(attribute_name)
      send(attribute_name)
    end

    def write_attribute(attribute_name, attribute_value)
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
      # match ActiveRecord #attributes= behavior on nil, scalars, etc.
      raise ArgumentError, "When assigning attributes, you must pass a hash as an argument." unless attributes.is_a?(Hash)

      multiparameter_attributes = {}
      attributes.each do |attribute_name, attribute_value|
        attribute_name = attribute_name.to_s
        if attribute_name.include?('(')
          multiparameter_attributes[attribute_name] = attribute_value
        else
          write_attribute(attribute_name, attribute_value)
        end
      end
      assign_multiparameter_attributes(multiparameter_attributes)
    end

  private
    def backing_model(backing_model_name)
      send(backing_model_name)
    end

    def backing_models
      self.class.exposed_attributes.keys.collect { |backing_model_name| backing_model(backing_model_name) }
    end

    def backing_object_for_attribute(attribute_name)
      self.class.exposed_attributes.each do |backing_model_name, attribute_names|
        return backing_model(backing_model_name) if attribute_names.include?(attribute_name.to_sym)
      end
      nil
    end
  end
end
