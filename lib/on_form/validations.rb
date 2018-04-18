module OnForm
  module Validations
    def self.included(base)
      base.validate :run_backing_model_validations
    end

    def invalid?
      !valid?
    end

  private
    def run_backing_model_validations
      backing_model_instances.each { |backing_model| backing_model.valid? }
    end

    def run_validations!
      super
      @_form_validation_errors = !errors.empty?
      collect_errors_from_backing_model_instances
      errors.empty?
    end
  end
end