module OnForm
  class Form
    include ActiveModel::Validations
    include Validations
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

    def self.identity_model_name
      @identity_model_name
    end

    class << self
      def inherited(child)
        exposed_attributes.each { |k, v| child.exposed_attributes[k].merge!(v) }
        child.introduced_attribute_types.merge!(introduced_attribute_types)
      end
    end

    def self.expose(backing_attribute_names, on: nil, prefix: nil, suffix: nil, as: nil)
      backing_attribute_names = Array(backing_attribute_names)
      raise ArgumentError, "can't expose multiple attributes as the same form attribute!" if as && backing_attribute_names.size != 1

      raise ArgumentError, "must choose the model to expose the attributes on" unless on || identity_model_name
      on = (on || identity_model_name).to_sym
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

    def self.take_identity_from(backing_model_name, convert_to_model: true)
      @identity_model_name = backing_model_name.to_sym
      expose_backing_model(@identity_model_name)
      delegate :id, :to_key, :to_param, :persisted?, :mark_for_destruction, :_destroy, :marked_for_destruction?, to: backing_model_name
      delegate :to_model, to: backing_model_name if convert_to_model
    end

    def self.expose_collection_of(association_name, on: nil, prefix: nil, suffix: nil, as: nil, allow_insert: true, allow_update: true, allow_destroy: false, &block)
      exposed_name = as || "#{prefix}#{association_name}#{suffix}"
      singular_name = exposed_name.to_s.singularize
      association_name = association_name.to_sym

      on = prepare_model_to_expose!(on)

      collection_form_class = Class.new(OnForm::Form)
      const_set(exposed_name.to_s.classify + "Form", collection_form_class)

      collection_form_class.send(:define_method, :initialize) { |record| @record = record }
      collection_form_class.send(:attr_reader, :record)
      collection_form_class.send(:alias_method, singular_name, :record)
      collection_form_class.take_identity_from singular_name, convert_to_model: false
      collection_form_class.class_eval(&block)

      define_method(exposed_name) { collection_wrappers[association_name] ||= CollectionWrapper.new(backing_model_instance(on), association_name, collection_form_class, allow_insert, allow_update, allow_destroy) } # used by action_view's fields_for, and by the following lines
      define_method("#{exposed_name}_attributes=") { |params| send(exposed_name).parse_collection_attributes(params) }
      define_method("_save_#{exposed_name}_forms") { send(exposed_name).save_forms }
      after_save :"_save_#{exposed_name}_forms"

      collection_form_class
    end

  protected
    def introduced_attribute_values
      @introduced_attribute_values ||= {}
    end

    def introduced_attribute_values_before_type_cast
      @introduced_attribute_values_before_type_cast ||= {}
    end

    def collection_wrappers
      @collection_wrappers ||= {}
    end

    def self.prepare_model_to_expose!(on)
      raise ArgumentError, "must choose the model to expose the attributes on" unless on || identity_model_name
      on = (on || identity_model_name).to_sym
      expose_backing_model(on)
      on
    end
  end
end
