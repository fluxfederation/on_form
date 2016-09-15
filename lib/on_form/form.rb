module OnForm
  class Form
    include Attributes
    include Errors
    include Saving

    extend ActiveModel::Translation

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
        attribute_names.each do |attribute_name|
          expose_attribute(backing_model_name, attribute_name)
        end
      end
    end

    def self.expose_attribute(backing_model_name, attribute_name)
      backing_model_name = backing_model_name.to_sym
      exposed_attributes[backing_model_name] << attribute_name.to_sym

      [attribute_name, "#{attribute_name}_before_type_cast"].each do |attribute_method|
        define_method(attribute_method) { backing_model(backing_model_name).send(attribute_method) }
      end
      ["#{attribute_name}="].each do |attribute_method|
        define_method(attribute_method) { |arg| backing_model(backing_model_name).send(attribute_method, arg) }
      end
    end
  end
end
