require "test_helper"

describe "a basic single-model form" do
  class Customer < ActiveRecord::Base
    validates_presence_of :name, :email, :phone_number
    validate :base_validation

    def base_validation
      errors.add(:base, "Customer needs to be friendly") unless friendly?
    end
  end

  class CustomerForm < Formulaic::Form
    attr_reader :customer

    expose :customer => %i(name email phone_number friendly)

    def initialize(customer)
      @customer = customer
    end
  end

  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @customer_form = CustomerForm.new(@customer)
  end

  it "returns exposed attribute values from attribute reader methods" do
    @customer_form.name.must_equal "Test User"
  end

  it "sets exposed attribute values from attribute writer methods" do
    @customer_form.name = "New Name"
    @customer.name.must_equal "New Name"
  end

  it "saves written attribute values" do
    @customer_form.name = "New Name 1"
    @customer_form.save!
    @customer.reload.name.must_equal "New Name 1"

    @customer_form.update!(name: "New Name 2")
    @customer.reload.name.must_equal "New Name 2"
  end

  it "raises ActiveRecord::RecordInvalid if a validation fails on save! or update!" do
    proc { @customer_form.update!(email: nil) }.must_raise(ActiveRecord::RecordInvalid)
    proc { @customer_form.save! }.must_raise(ActiveRecord::RecordInvalid)
  end

  it "returns false if a validation fails on save or update" do
    @customer_form.update(email: nil).must_equal false
    @customer_form.save.must_equal false
  end

  it "exposes validation errors on attributes" do
    @customer_form.email = nil
    @customer_form.save.must_equal false
    @customer_form.errors.full_messages.must_equal ["Email can't be blank"]
    @customer_form.errors[:email].must_equal ["can't be blank"]

    begin
      @customer_form.name = ""
      @customer_form.save!
      fail
    rescue ActiveRecord::RecordInvalid
      @customer_form.errors.full_messages.sort.must_equal ["Email can't be blank", "Name can't be blank"]
      @customer_form.errors[:name].must_equal ["can't be blank"]
    end
  end

  it "exposes validation errors on base" do
    @customer_form.friendly = false
    @customer_form.save.must_equal false
    @customer_form.errors.full_messages.must_equal ["Customer needs to be friendly"]
    @customer_form.errors[:base].must_equal ["Customer needs to be friendly"]
  end
end
