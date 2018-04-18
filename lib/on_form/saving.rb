module OnForm
  module Saving
    def self.included(base)
      base.define_model_callbacks :save
    end

    def transaction(&block)
      backing_models = backing_model_instances

      if backing_models.empty?
        with_transactions([ActiveRecord::Base], &block)
      else
        with_transactions(backing_model_instances, &block)
      end
    end

    def save!
      transaction do
        reset_errors

        run_validations!

        if !errors.empty?
          if @_form_validation_errors
            raise ActiveModel::ValidationError, self
          else
            raise ActiveRecord::RecordInvalid, self
          end
        end

        run_callbacks :save do
          # we pass (validate: false) to avoid running the validations a second time, but we use save! to get the RecordNotFound behavior
          backing_model_instances.each { |backing_model| backing_model.save!(validate: false) }
        end
      end
      true
    end

    def save
      save!
    rescue ActiveRecord::RecordInvalid, ActiveModel::ValidationError
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
  end
end
