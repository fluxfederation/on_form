require "test_helper"

module AccountFormComponent
  def self.included(form)
    form.expose %i(email phone_number), on: :customer
  end
end

class NewAccountForm < OnForm::Form
  include AccountFormComponent

  expose %i(name), on: :customer

  def initialize(customer)
    @customer = customer
  end
end

class EditAccountForm < OnForm::Form
  include AccountFormComponent

  delegate :name, to: :customer

  def initialize(customer)
    @customer = customer
  end
end

describe "form modules" do
  it "exposes common fields in all forms including the module" do
    EditAccountForm.exposed_attributes[:customer].must_include :email
    EditAccountForm.exposed_attributes[:customer].must_include :phone_number
    NewAccountForm.exposed_attributes[:customer].must_include :email
    NewAccountForm.exposed_attributes[:customer].must_include :phone_number
  end

  it "exposes new fields added in forms outside the module" do
    NewAccountForm.exposed_attributes[:customer].must_include :name
    EditAccountForm.exposed_attributes[:customer].wont_include :name
  end

  it "sets both attributes defined in modules and attributes defined in the form" do
    Customer.delete_all
    @customer = Customer.new
    @new_account_form = NewAccountForm.new(@customer)
    @new_account_form.update!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @customer.reload.name.must_equal "Test User"
    @customer.email.must_equal "test@example.com"
  end
end
