class Customer < ActiveRecord::Base
  validates_presence_of :name, :email, :phone_number
  validate :base_validation

  def base_validation
    errors.add(:base, "Customer needs to be friendly") unless friendly?
  end
end
