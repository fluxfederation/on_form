module OnForm
  module Saving
    def self.included(base)
      base.define_model_callbacks :save
    end

    def transaction(&block)
      with_transactions(backing_models, &block)
    end

    def invalid?
      !valid?
    end

    def save!
      reset_errors
      transaction do
        reset_errors
        unless run_validations!(backing_model_validations: false)
          raise ActiveRecord::RecordInvalid, self
        end
        run_callbacks :save do
          begin
            backing_models.each { |backing_model| backing_model.save! }
          rescue ActiveRecord::RecordInvalid
            collect_errors
            raise
          end
        end
      end
      true
    end

    def save
      save!
    rescue ActiveRecord::RecordInvalid
      false
    end

    def update(attributes)
      transaction do
        self.attributes = attributes
        save
      end
    end

    def update!(attributes)
      transaction do
        self.attributes = attributes
        save!
      end
    end

    alias :update_attributes :update
    alias :update_attributes! :update!

  private
    def with_transactions(models, &block)
      if models.empty?
        block.call
      else
        models.shift.transaction do
          with_transactions(models, &block)
        end
      end
    end

    def run_validations!(backing_model_validations: true)
      super()
      run_backing_model_validations if backing_model_validations
      errors.empty?
    end

    def run_backing_model_validations
      backing_models.collect { |backing_model| backing_model.valid? }
      collect_errors
    end
  end
end
