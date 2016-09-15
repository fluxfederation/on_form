module OnForm
  module Saving
    def transaction(&block)
      with_transactions(backing_models, &block)
    end

    def valid?
      reset_errors
      transaction do
        backing_models.collect { |backing_model| backing_model.valid? }.reduce(:|)
      end
    end

    def save!
      reset_errors
      transaction do
        backing_models.each { |backing_model| backing_model.save! }
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
  end
end
