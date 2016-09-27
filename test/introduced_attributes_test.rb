require "test_helper"

class ChangeEmailForm < OnForm::Form
  expose %i(email), on: :customer, as: :new_email
  attribute :email_confirmation, :string, :default => "(please confirm)"

  validate :email_confirmation_matches

  def initialize(customer)
    @customer = customer
  end

  def email_confirmation_matches
    errors[:email_confirmation] << "does not match" unless email_confirmation == new_email
  end
end

class AttributeDefaultsForm < OnForm::Form
  attribute :integer_with_no_default, :integer
  attribute :integer_with_default, :integer, :default => 42
  attribute :decimal_with_default, :decimal, :default => "12.34", :scale => 2, :precision => 4
end

describe "introduced attributes" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @change_email_form = ChangeEmailForm.new(@customer)
  end

  it "can be read from and written to" do
    @change_email_form.email_confirmation.must_equal "(please confirm)"
    @change_email_form.email_confirmation_was.must_equal "(please confirm)"
    @change_email_form.email_confirmation_changed?.must_equal false

    @change_email_form.email_confirmation = "new@example.com"

    @change_email_form.email_confirmation.must_equal "new@example.com"
    @change_email_form.email_confirmation_was.must_equal "(please confirm)"
    @change_email_form.email_confirmation_changed?.must_equal true
  end

  it "doesn't confuse nil with 0" do
    @form = AttributeDefaultsForm.new
    @form.integer_with_no_default.must_equal nil
    @form.integer_with_no_default_changed?.must_equal false

    @form.integer_with_no_default = 0
    @form.integer_with_no_default.must_equal 0
    @form.integer_with_no_default_changed?.must_equal true

    @form.integer_with_no_default = 23
    @form.integer_with_no_default.must_equal 23
    @form.integer_with_no_default_changed?.must_equal true

    @form.integer_with_no_default = "16"
    @form.integer_with_no_default.must_equal 16
    @form.integer_with_no_default_changed?.must_equal true

    @form.integer_with_no_default = ""
    @form.integer_with_no_default.must_equal nil
    @form.integer_with_no_default_changed?.must_equal false

    @form.integer_with_default.must_equal 42
    @form.integer_with_default_changed?.must_equal false

    @form.integer_with_default = 0
    @form.integer_with_default.must_equal 0
    @form.integer_with_default_changed?.must_equal true

    @form.integer_with_default = "16"
    @form.integer_with_default.must_equal 16
    @form.integer_with_default_changed?.must_equal true

    @form.integer_with_default = ""
    @form.integer_with_default.must_equal nil
    @form.integer_with_default_changed?.must_equal true

    @form.integer_with_default = nil
    @form.integer_with_default.must_equal nil
    @form.integer_with_default_changed?.must_equal true

    @form.integer_with_no_default_was.must_equal nil
    @form.integer_with_default_was.must_equal 42

    @form.decimal_with_default.must_equal BigDecimal.new("12.34")
    @form.decimal_with_default_changed?.must_equal false

    @form.decimal_with_default = "23.456" # should get rounded
    @form.decimal_with_default.must_equal BigDecimal.new("23.46")
    @form.decimal_with_default_changed?.must_equal true
  end
end
