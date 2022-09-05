module OnForm
  module Errors
    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    def reset_errors
      @errors = nil
      reset_errors_on_child_forms
    end

  private
    def reset_errors_on_child_forms
      collection_wrappers.each_value(&:reset_forms_errors)
    end

    def collect_errors_from_backing_model_instances
      self.class.exposed_attributes.each do |backing_model_name, attribute_mappings|
        backing_model = backing_model_instance(backing_model_name)

        collect_errors_on(backing_model, :base, :base)

        attribute_mappings.each do |exposed_name, backing_name|
          collect_errors_on(backing_model, exposed_name, backing_name)
        end
      end
    end

    def collect_errors_on(backing_model, exposed_name, backing_name)
      Array(backing_model.errors[backing_name]).each { |error| errors.add(exposed_name, error) }
    end
  end
end
