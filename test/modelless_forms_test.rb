require "test_helper"

def dummy_password_hash(password)
  # obviously, don't copy this!  use BCrypt in a real app.  we would use it here, but we don't want to add a gem dependency just for this test.
  password.reverse if password
end

class ChangePasswordForm < OnForm::Form
  attribute :current_password, :string
  attribute :password, :string
  attribute :password_confirmation, :string

  validate :current_password_correct
  validate :password_confirmation_matches
  before_save :set_new_password

  def initialize(customer)
    @customer = customer
  end

  def current_password_correct
    unless dummy_password_hash(current_password) == @customer.password_digest
      errors[:current_password] << "is incorrect"
    end
  end

  def password_confirmation_matches
    unless password_confirmation == password
      errors[:password_confirmation] << "doesn't match"
    end
  end

  def set_new_password
    @customer.update!(password_digest: dummy_password_hash(password))
  end
end

describe "model-less forms" do
  before do
    Customer.delete_all
    @customer = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567",
      :password_digest => dummy_password_hash("oldpassword"))
    @change_password_form = ChangePasswordForm.new(@customer)
  end

  it "runs validations" do
    @change_password_form.password = "newpassword"
    @change_password_form.valid?.must_equal false
    @change_password_form.errors[:current_password].must_equal ["is incorrect"]
    @change_password_form.errors[:password_confirmation].must_equal ["doesn't match"]

    @change_password_form.password_confirmation = "newpassword"
    @change_password_form.valid?.must_equal false
    @change_password_form.errors[:current_password].must_equal ["is incorrect"]
    @change_password_form.errors[:password_confirmation].must_equal []

    @change_password_form.current_password = "oldpassword"
    @change_password_form.valid?.must_equal true
    @change_password_form.errors[:current_password].must_equal []
    @change_password_form.errors[:password_confirmation].must_equal []
  end

  it "performs updates" do
    @change_password_form.update!(current_password: "oldpassword", password: "newpassword", password_confirmation: "newpassword")
    @customer.reload.password_digest.must_equal dummy_password_hash("newpassword")
  end
end
