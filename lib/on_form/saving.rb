module OnForm
  module Saving
    def valid?
      reset_errors
      backing_models.collect { |backing_model| backing_model.valid? }.reduce(:|)
    end

    def save!
      reset_errors
      backing_models.each { |backing_model| backing_model.save! }
      true
    end

    def save
      save!
    rescue ActiveRecord::RecordInvalid
      false
    end

    def update(attributes)
      self.attributes = attributes
      save
    end

    def update!(attributes)
      self.attributes = attributes
      save!
    end

    alias :update_attributes :update
    alias :update_attributes! :update!
  end
end
