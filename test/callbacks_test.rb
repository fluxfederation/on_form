require "test_helper"

module TestCallbacks
  def self.included(base)
    base.send :attr_accessor, :save_logs_in, :fail_validation

    base.before_validation :log_before_validation
    base.validate          :log_validate

    base.before_save :log_before_save
    base.after_save  :log_after_save
    base.around_save :log_around_save
  end

  def log_before_validation
    save_logs_in << "#{self.class.name} before_validation" if save_logs_in
    errors.add(:base, "failing validation") if fail_validation
  end

  def log_validate
    save_logs_in << "#{self.class.name} validate" if save_logs_in
  end

  def log_before_save
    save_logs_in << "#{self.class.name} before_save" if save_logs_in
  end

  def log_after_save
    save_logs_in << "#{self.class.name} after_save" if save_logs_in
  end

  def log_around_save
    save_logs_in << "#{self.class.name} around_save begins" if save_logs_in
    yield
    save_logs_in << "#{self.class.name} around_save ends" if save_logs_in
  end
end

class CallbackHouse < ActiveRecord::Base
  validates_presence_of :vendor, :street_number, :street_name, :city
  belongs_to :vendor, :class_name => 'Customer'

  self.table_name = "houses"

  include TestCallbacks
end

class SaveCallbackForm < OnForm::Form
  expose :house => %i(street_number street_name city),
         :vendor => %i(name phone_number)

  include TestCallbacks

  def initialize(house)
    @house = house
    @vendor = house.vendor
  end
end

describe "callbacks" do
  before do
    Customer.delete_all
    House.delete_all
    @vendor = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @house = CallbackHouse.create!(:vendor => @vendor, :street_number => "8/90", :street_name => "Main Street", :city => "Townsville")
    @save_callback_form = SaveCallbackForm.new(@house)
    @save_callback_form.save_logs_in = @house.save_logs_in = @logs = []
    @save_callback_form.street_number = "1"
  end

  it "fires the save callbacks in order, with the form callbacks occurring before the model callbacks" do
    @logs.must_equal []
    @save_callback_form.save!
    @logs.must_equal [
      "SaveCallbackForm before_validation",
      "SaveCallbackForm validate",
      "SaveCallbackForm before_save",
      "SaveCallbackForm around_save begins",
        "CallbackHouse before_validation",
        "CallbackHouse validate",
        "CallbackHouse before_save",
        "CallbackHouse around_save begins",
        "CallbackHouse around_save ends",
        "CallbackHouse after_save",
      "SaveCallbackForm around_save ends",
      "SaveCallbackForm after_save",
    ]
  end

  it "stops before saving if the form validations fail" do
    @save_callback_form.fail_validation = true
    @logs.must_equal []
    proc { @save_callback_form.save! }.must_raise ActiveRecord::RecordInvalid
    @save_callback_form.errors[:base].must_equal ["failing validation"]
    @logs.must_equal [
      "SaveCallbackForm before_validation",
      "SaveCallbackForm validate",
    ]
  end

  it "stops during saving if the model validations fail" do
    @house.fail_validation = true
    @logs.must_equal []
    proc { @save_callback_form.save! }.must_raise ActiveRecord::RecordInvalid
    @save_callback_form.errors[:base].must_equal ["failing validation"]
    @logs.must_equal [
      "SaveCallbackForm before_validation",
      "SaveCallbackForm validate",
      "SaveCallbackForm before_save",
      "SaveCallbackForm around_save begins",
        "CallbackHouse before_validation",
        "CallbackHouse validate",
    ]
  end
end
