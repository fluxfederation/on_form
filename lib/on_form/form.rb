module OnForm
  class Form
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    include Attributes
    include MultiparameterAttributes
    include Errors
    include Saving

    def self.exposed_attributes
      @exposed_attributes ||= Hash.new { |h, k| h[k] = [] }
    end

    class << self
      def inherited(child)
        exposed_attributes.each { |k, v| child.exposed_attributes[k].concat(v) }
      end
    end

    def self.expose(attribute_names, on:)
      on = on.to_sym
      expose_backing_model(on)
      attribute_names.each do |attribute_name|
        expose_attribute(on, attribute_name)
      end
    end

  protected
    def self.expose_backing_model(backing_model_name)
      unless instance_methods.include?(backing_model_name)
        attr_reader backing_model_name
      end
    end

    def self.expose_attribute(backing_model_name, attribute_name)
      exposed_attributes[backing_model_name] << attribute_name.to_sym

      [attribute_name, "#{attribute_name}_before_type_cast", "#{attribute_name}?"].each do |attribute_method|
        define_method(attribute_method) { backing_model(backing_model_name).send(attribute_method) }
      end
      ["#{attribute_name}="].each do |attribute_method|
        define_method(attribute_method) { |arg| backing_model(backing_model_name).send(attribute_method, arg) }
      end
    end
  end
end
