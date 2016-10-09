class Customer < ActiveRecord::Base
  validates_presence_of :name, :email, :phone_number
  validate :base_validation

  def base_validation
    errors.add(:base, "Customer needs to be friendly") unless friendly?
  end
end

class House < ActiveRecord::Base
  belongs_to :vendor, :class_name => 'Customer'
  has_many   :house_rooms, :inverse_of => :house

  validates_presence_of :vendor, :street_number, :street_name, :city
end

class HouseRoom < ActiveRecord::Base
  belongs_to :house

  validates_presence_of :house, :name, :area
end
