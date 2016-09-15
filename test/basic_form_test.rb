require "test_helper"

class PreferencesForm < OnForm::Form
  expose :customer => %i(name email phone_number friendly)

  def initialize(customer)
    @customer = customer
  end
end

describe "a basic single-model form" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @preferences_form = PreferencesForm.new(@customer)
  end

  it "doesn't allow access to un-exposed attributes" do
    proc { @preferences_form.created_at }.must_raise(NoMethodError)
    proc { @preferences_form.verified }.must_raise(NoMethodError)
    proc { @preferences_form.verified = true }.must_raise(NoMethodError)
  end

  it "returns exposed attribute values from attribute reader methods" do
    @preferences_form.name.must_equal "Test User"
  end

  it "sets exposed attribute values from attribute writer methods" do
    @preferences_form.name = "New Name"
    @customer.name.must_equal "New Name"
  end

  it "lists attribute names" do
    # expect strings back for compatibility with ActiveRecord
    @preferences_form.attribute_names.sort.must_equal %w(name email phone_number friendly).sort
  end

  it "returns all attributes in a hash from attributes" do
    @preferences_form.attributes.must_equal({"name" => "Test User", "email" => "test@example.com", "phone_number" => "123-4567", "friendly" => true})
  end

  it "sets exposed attribute values from mass assignment to attributes=" do
    @preferences_form.attributes = {name: "New Name"}
    @customer.name.must_equal "New Name"
  end

  it "saves written attribute values" do
    @preferences_form.name = "New Name 1"
    @preferences_form.save!
    @customer.reload.name.must_equal "New Name 1"

    @preferences_form.update!(name: "New Name 2")
    @customer.reload.name.must_equal "New Name 2"
  end

  it "returns false from valid? if a validation fails" do
    @preferences_form.valid?.must_equal true
    @preferences_form.email = nil
    @preferences_form.valid?.must_equal false
  end

  it "raises ActiveRecord::RecordInvalid from save! or update! if a validation fails" do
    proc { @preferences_form.update!(email: nil) }.must_raise(ActiveRecord::RecordInvalid)
    proc { @preferences_form.save! }.must_raise(ActiveRecord::RecordInvalid)
  end

  it "returns false from save or update if a validation fails" do
    @preferences_form.update(email: nil).must_equal false
    @preferences_form.save.must_equal false
  end

  it "exposes validation errors on attributes" do
    @preferences_form.email = nil
    @preferences_form.save.must_equal false
    @preferences_form.errors.full_messages.must_equal ["Email can't be blank"]
    @preferences_form.errors[:email].must_equal ["can't be blank"]

    begin
      @preferences_form.name = ""
      @preferences_form.save!
      fail
    rescue ActiveRecord::RecordInvalid
      @preferences_form.errors.full_messages.sort.must_equal ["Email can't be blank", "Name can't be blank"]
      @preferences_form.errors[:name].must_equal ["can't be blank"]
    end
  end

  it "exposes validation errors on base" do
    @preferences_form.friendly?.must_equal true
    @preferences_form.friendly = false
    @preferences_form.save.must_equal false
    @preferences_form.errors.full_messages.must_equal ["Customer needs to be friendly"]
    @preferences_form.errors[:base].must_equal ["Customer needs to be friendly"]
  end
end
