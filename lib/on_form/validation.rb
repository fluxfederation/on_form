module OnForm
  module Validation

    def invalid?
      !valid?
    end

    def run_backing_model_validation!
      backing_model_instances.collect { |backing_model| backing_model.valid? }
      collect_errors
      run_child_form_backing_model_validation!
    end

    def run_validations!
      super()
      run_backing_model_validation! if backing_model_validations
      run_child_form_validation!
      errors.empty?
    end

    protected

    def run_child_form_backing_model_validation!
      collection_wrappers.each_value { |collection| collection.run_forms_backing_models_validations(self) }
    end

    def run_child_form_validation!
      collection_wrappers.each_value {|collection| collection.validate_forms(self) }
    end
  end
end
