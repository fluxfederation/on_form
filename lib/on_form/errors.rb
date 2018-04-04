module OnForm
  module Errors
    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    private
    def reset_errors
      @errors = nil
    end

    def collect_errors
      self.class.exposed_attributes.each do |backing_model_name, attribute_mappings|
        backing_model = backing_model_instance(backing_model_name)

        collect_errors_on(backing_model, :base, :base)

        attribute_mappings.each do |exposed_name, backing_name|
          collect_errors_on(backing_model, exposed_name, backing_name)
        end

        add_collection_form_errors(backing_model_name)
      end
    end

    def add_collection_form_errors(backing_model_name)
      return unless collection_wrappers[backing_model_name].present?

      collection_wrappers[backing_model_name].each do |association_name, collection_wrapper|
        association_exposed_name = collection_wrapper[:exposed_name]

        collection_wrapper[:form].loaded_forms.each do |child_form|
          next unless child_form.errors.present?

          collect_errors_on(child_form.record, :"#{association_exposed_name}", :base)

          child_form.class.exposed_attributes.each do |_child_model_name, attribute_mappings|
            attribute_mappings.each do |exposed_name, backing_name|
              collect_errors_on(child_form.record, :"#{association_exposed_name}.#{exposed_name}", backing_name)
            end
          end
        end
      end
    end

    def collect_errors_on(backing_model, exposed_name, backing_name)
      Array(backing_model.errors[backing_name]).each { |error| errors[exposed_name] << error }
    end
  end
end
