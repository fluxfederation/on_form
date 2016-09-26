require "test_helper"

class PersonalDetailsForm < OnForm::Form
  expose %i(name date_of_birth married_at), on: :customer

  def initialize(customer)
    @customer = customer
  end
end

describe "multi-parameter attributes" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567", date_of_birth: "1971-02-03")
    @personal_details_form = PersonalDetailsForm.new(@customer)
  end

  it "accepts writes the whole attribute" do
    @personal_details_form.update!("date_of_birth" => Date.new(1982, 3, 4))
    @customer.date_of_birth.must_equal Date.new(1982, 3, 4)
    @customer.reload.date_of_birth.must_equal Date.new(1982, 3, 4)
  end

  it "accepts writes using multi-parameter attributes" do
    @personal_details_form.update!("date_of_birth(1i)" => "1982", "date_of_birth(2i)" => "3", "date_of_birth(3i)" => "4")
    @customer.date_of_birth.must_equal Date.new(1982, 3, 4)
    @customer.reload.date_of_birth.must_equal Date.new(1982, 3, 4)
  end

  it "applies default values for missing right-most multi-parameter attributes" do
    @personal_details_form.update!("married_at(1i)" => "2016", "married_at(2i)" => "9", "married_at(3i)" => "15", "married_at(4i)" => "10", "married_at(5i)" => "50")
    @customer.married_at.must_equal Time.utc(2016, 9, 15, 10, 50, 0)
    @customer.reload.married_at.must_equal Time.utc(2016, 9, 15, 10, 50, 0)
  end
end
