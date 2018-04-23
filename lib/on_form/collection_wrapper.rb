module OnForm
  class CollectionWrapper
    include ::Enumerable
    attr_reader :parent, :association_name, :collection_form_class,
                :allow_insert, :allow_update, :allow_destroy, :reject_if

    delegate :each, :first, :last, :[], to: :to_a

    def initialize(parent, association_name, collection_form_class, allow_insert: true, allow_update: true, allow_destroy: false, reject_if: nil)
      @parent = parent
      @association_name = association_name
      @association = parent.association(association_name)
      @association_proxy = parent.send(association_name)
      @collection_form_class = collection_form_class
      @allow_insert, @allow_update, @allow_destroy, @reject_if = allow_insert, allow_update, allow_destroy, reject_if
      @wrapped_records = {}
      @wrapped_new_records = []
      @loaded_forms = []
    end

    def to_ary
      to_a
    end

    def each
      @association_proxy.each { |record| yield wrapped_record(record) }
    end

    def size
      @association_proxy.size
    end

    def save_forms(validate: true)
      @loaded_forms.each do |form|
        if form.marked_for_destruction?
          form.record.destroy
        else
          form.save!(validate: validate)
        end
      end
    end

    def validate_forms(parent_form)
      @loaded_forms.collect do |form|
        add_errors_to_parent(parent_form, form) if form.invalid?
      end
    end

    def form_errors?
      @loaded_forms.map(&:form_errors?).any?
    end

    def reset_forms_errors
      @loaded_forms.collect(&:reset_errors)
    end

    def parse_collection_attributes(params)
      params = params.values unless params.is_a?(Array)

      records_to_insert = []
      records_to_update = {}
      records_to_destroy = []

      params.each do |attributes|
        destroy = self.class.boolean_type.cast(attributes['_destroy']) || self.class.boolean_type.cast(attributes[:_destroy])
        if id = attributes['id'] || attributes[:id]
          if destroy
            records_to_destroy << id.to_i if allow_destroy
          elsif allow_update && !call_reject_if(attributes)
            records_to_update[id.to_i] = attributes.except('id', :id, '_destroy', :destroy)
          end
        elsif !destroy && allow_insert && !call_reject_if(attributes)
          records_to_insert << attributes.except('_destroy', :destroy)
        end
      end

      to_a if @association_proxy.loaded?
      records_to_load = records_to_update.keys + records_to_destroy - @wrapped_records.keys.collect(&:id)
      @association_proxy.find(records_to_load).each do |record|
        @association.add_to_target(record, :skip_callbacks)
        wrapped_record(record)
      end
      loaded_forms_by_id = @wrapped_records.values.index_by(&:id)

      records_to_insert.each do |attributes|
        wrapped_record(@association_proxy.build).attributes = attributes
      end

      records_to_update.each do |id, attributes|
        loaded_forms_by_id[id].attributes = attributes
      end

      records_to_destroy.each do |id|
        loaded_forms_by_id[id].mark_for_destruction
      end

      params
    end

  protected
    def self.boolean_type
      @boolean_type ||= Types.lookup(:boolean, {})
    end

    def add_errors_to_parent(parent_form, child_form)
      return unless child_form.errors.present?

      association_exposed_name = child_form.class.identity_model_name.to_s.pluralize
      child_form.errors.each do |attribute, errors|
        Array(errors).each { |error| parent_form.errors["#{association_exposed_name}.#{attribute}"] << error }
        if parent_form.errors["#{association_exposed_name}.#{attribute}"].present?
          parent_form.errors["#{association_exposed_name}.#{attribute}"].uniq!
        end
      end
    end

    def wrapped_record(record)
      @wrapped_records[record] ||= @collection_form_class.new(record).tap { |form| @loaded_forms << form }
    end

    # Determines if a record with the particular +attributes+ should be
    # rejected by calling the reject_if Symbol or Proc (if defined).
    # The reject_if option is defined by +expose_collection_of+.
    def call_reject_if(attributes)
      case reject_if
      when Symbol
        @collection_form_class.method(reject_if).arity == 0 ? @collection_form_class.send(reject_if) : @collection_form_class.send(reject_if, attributes)
      when Proc
        reject_if.call(attributes)
      else
        false
      end
    end
  end
end
