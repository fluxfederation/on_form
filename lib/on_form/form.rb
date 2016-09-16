module OnForm
  class Form
    include Attributes
    include MultiparameterAttributes
    include Errors
    include Saving

    extend ActiveModel::Translation
    extend ActiveModel::Callbacks

    define_model_callbacks :save

    def self.exposed_attributes
      @exposed_attributes ||= Hash.new { |h, k| h[k] = [] }
    end

    class << self
      def inherited(child)
        exposed_attributes.each { |k, v| child.exposed_attributes[k].concat(v) }
      end
    end

    def self.expose(backing_models_and_attribute_names)
      backing_models_and_attribute_names.each do |backing_model_name, attribute_names|
        backing_model_name = backing_model_name.to_sym
        expose_backing_model(backing_model_name)
        attribute_names.each do |attribute_name|
          expose_attribute(backing_model_name, attribute_name)
        end
      end
    end

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
