module OnForm
  class Form
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks

    include Attributes
    include MultiparameterAttributes
    include Errors
    include Saving

    def self.exposed_attributes
      @exposed_attributes ||= Hash.new { |h, k| h[k] = {} }
    end

    def self.introduced_attribute_types
      @introduced_attribute_types ||= {}
    end

    class << self
      def inherited(child)
        exposed_attributes.each { |k, v| child.exposed_attributes[k].merge!(v) }
        child.introduced_attribute_types.merge!(introduced_attribute_types)
      end
    end

    def self.expose(backing_attribute_names, on:, prefix: nil, suffix: nil, as: nil)
      raise ArgumentError, "can't expose multiple attributes as the same form attribute!" if as && backing_attribute_names.size != 1
      on = on.to_sym
      expose_backing_model(on)
      backing_attribute_names.each do |backing_name|
        exposed_name = as || "#{prefix}#{backing_name}#{suffix}"
        expose_attribute(on, exposed_name, backing_name)
      end
    end

    def self.expose_backing_model(backing_model_name)
      unless instance_methods.include?(backing_model_name)
        attr_reader backing_model_name
      end
    end

    def self.expose_attribute(backing_model_name, exposed_name, backing_name)
      exposed_attributes[backing_model_name][exposed_name.to_sym] = backing_name.to_sym

      define_method(exposed_name)                       { backing_model_instance(backing_model_name).send(backing_name) }
      define_method("#{exposed_name}_before_type_cast") { backing_model_instance(backing_model_name).send("#{backing_name}_before_type_cast") }
      define_method("#{exposed_name}?")                 { backing_model_instance(backing_model_name).send("#{backing_name}?") }
      define_method("#{exposed_name}_changed?")         { backing_model_instance(backing_model_name).send("#{backing_name}_changed?") }
      define_method("#{exposed_name}_was")              { backing_model_instance(backing_model_name).send("#{backing_name}_was") }
      define_method("#{exposed_name}=")                 { |arg| backing_model_instance(backing_model_name).send("#{backing_name}=", arg) }
    end

    def self.attribute(name, type, options = {})
      name = name.to_sym
      introduced_attribute_types[name] = Types.lookup(type, options)
      define_method(name)                       { introduced_attribute_values.fetch(name) { type = self.class.introduced_attribute_types[name]; type.cast(introduced_attribute_values_before_type_cast.fetch(name) { type.default }) } }
      define_method("#{name}_before_type_cast") { introduced_attribute_values_before_type_cast[name] }
      define_method("#{name}_changed?")         { send(name) != send("#{name}_was") }
      define_method("#{name}_was")              { type = self.class.introduced_attribute_types[name]; type.cast(type.default) }
      define_method("#{name}=")                 { |arg| introduced_attribute_values.delete(name); introduced_attribute_values_before_type_cast[name] = arg }
    end

  protected
    def introduced_attribute_values
      @introduced_attribute_values ||= {}
    end

    def introduced_attribute_values_before_type_cast
      @introduced_attribute_values_before_type_cast ||= {}
    end
  end
end
