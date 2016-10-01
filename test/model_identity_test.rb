require "test_helper"

class PhoneNumberWithoutIdentityForm < OnForm::Form
  expose %i(phone_number), on: :customer

  def initialize(customer)
    @customer = customer
  end
end

class PhoneNumberWithIdentityForm < OnForm::Form
  take_identity_from :customer
  expose %i(phone_number), on: :customer

  def initialize(customer)
    @customer = customer
  end
end

class PhoneNumberWithIdentityUsingDefaultForm < OnForm::Form
  take_identity_from :customer
  expose %i(phone_number)

  def initialize(customer)
    @customer = customer
  end
end

describe "model identity" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
  end

  it "doesn't implement persisted? by default" do # relevant as form_for checks respond_to?(:persisted?)
    @form = PhoneNumberWithoutIdentityForm.new(@customer)
    proc { @form.persisted? }.must_raise(NoMethodError)
  end

  it "gives the model passed to take_identity_from's to_key and to_param" do
    @form = PhoneNumberWithIdentityForm.new(@customer)
    @form.to_key.must_equal @customer.to_key
    @form.to_param.must_equal @customer.to_param
  end

  it "defaults to exposing attributes from the model passed to take_identity_from" do
    @form = PhoneNumberWithIdentityUsingDefaultForm.new(@customer)
    @form.phone_number.must_equal @customer.phone_number
  end
end
