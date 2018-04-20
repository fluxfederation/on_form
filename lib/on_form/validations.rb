module OnForm
  module Validations
    def self.included(base)
      base.validate :run_backing_model_validations
    end

    def invalid?
      !valid?
    end

    def form_errors?
      !!(@_form_validation_errors || child_form_errors?)
    end

  private
    def run_backing_model_validations
      backing_model_instances.each { |backing_model| backing_model.valid? }
    end

    def run_validations!
      super
      @_form_validation_errors = !errors.empty?
      collect_errors_from_backing_model_instances
      run_child_form_validations!
      errors.empty?
    end

    def run_child_form_validations!
      collection_wrappers.each_value {|collection| collection.validate_forms(self) }
    end

    def child_form_errors?
      collection_wrappers.values.map(&:form_errors?).any?
    end
  end
end
