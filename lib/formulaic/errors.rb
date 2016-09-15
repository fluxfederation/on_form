module Formulaic
  module Errors
    def errors
      @errors ||= collect_errors
    end

  private
    def reset_errors
      @errors = nil
    end

    def collect_errors
      ActiveModel::Errors.new(self).tap do |errors|
        self.class.exposed_attributes.each do |backing_model_name, exposed_attributes_on_backing_model|
          backing_model_errors = backing_model(backing_model_name).errors
          backing_model_errors.each do |backing_attribute, attribute_errors|
            if backing_attribute == :base || exposed_attributes_on_backing_model.include?(backing_attribute)
              Array(attribute_errors).each { |error| errors[backing_attribute] << error }
            end
          end
        end
      end
    end
  end
end
