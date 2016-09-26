require "test_helper"

class AccountHolderForm < OnForm::Form
  expose %i(name date_of_birth), on: :customer, prefix: "account_holder_"
  expose %i(email), on: :customer, suffix: "_for_billing"
  expose %i(phone_number), on: :customer, as: "mobile_number"

  def initialize(customer)
    @customer = customer
  end
end

describe "attribute renaming" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567", date_of_birth: "2001-02-03")
    @account_holder_form = AccountHolderForm.new(@customer)
  end

  it "applies prefixes" do
    @account_holder_form.attribute_names.must_equal %w(account_holder_name account_holder_date_of_birth email_for_billing mobile_number)

    @account_holder_form.account_holder_name.must_equal "Test User"
    @account_holder_form.account_holder_name = "Renamed User"
    @customer.name.must_equal "Renamed User"

    @account_holder_form.account_holder_name = nil
    @account_holder_form.valid?.must_equal false
    @account_holder_form.errors.keys.must_equal [:account_holder_name]
    @account_holder_form.errors[:account_holder_name].must_equal ["can't be blank"]

    proc { @account_holder_form.name }.must_raise(NoMethodError)
    proc { @account_holder_form.name = "test" }.must_raise(NoMethodError)
  end

  it "applies suffixes" do
    @account_holder_form.email_for_billing.must_equal "test@example.com"
    @account_holder_form.email_for_billing = "newemail@example.com"
    @customer.email.must_equal "newemail@example.com"

    proc { @account_holder_form.email }.must_raise(NoMethodError)
    proc { @account_holder_form.email = "test" }.must_raise(NoMethodError)
  end

  it "applies complete renames" do
    @account_holder_form.mobile_number.must_equal "123-4567"
    @account_holder_form.mobile_number = "123-4568"
    @customer.phone_number.must_equal "123-4568"

    proc { @account_holder_form.phone_number }.must_raise(NoMethodError)
    proc { @account_holder_form.phone_number = "test" }.must_raise(NoMethodError)
  end

  it "supports multiparameter attributes" do
    @account_holder_form.account_holder_date_of_birth.must_equal Date.new(2001, 2, 3)
    @account_holder_form.update!("account_holder_date_of_birth(1i)" => "1982", "account_holder_date_of_birth(2i)" => "3", "account_holder_date_of_birth(3i)" => "4")
    @customer.date_of_birth.must_equal Date.new(1982, 3, 4)
  end
end
