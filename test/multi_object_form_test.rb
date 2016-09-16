require "test_helper"

class HouseListingForm < OnForm::Form
  expose :house => %i(street_number street_name city),
         :vendor => %i(name phone_number)

  def initialize(house)
    @house = house
    @vendor = house.vendor
  end
end

class DelegatedHouseListingForm < OnForm::Form
  delegate :vendor, :to => :house

  expose :house => %i(street_number street_name city),
         :vendor => %i(name phone_number)

  def initialize(house)
    @house = house
  end
end

describe "multi-record form" do
  before do
    Customer.delete_all
    House.delete_all
    @vendor = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @house = House.create!(:vendor => @vendor, :street_number => "8/90", :street_name => "Main Street", :city => "Townsville")
    @house_listing_form = HouseListingForm.new(@house)
  end

  it "exposes attributes from all models" do
    @house_listing_form.street_number.must_equal "8/90"
    @house_listing_form.phone_number.must_equal "123-4567"
  end

  it "saves changes to all models" do
    @house_listing_form.update!(:street_name => "Small Street", :phone_number => "222-3333")
    @house.reload.street_name.must_equal "Small Street"
    @vendor.reload.phone_number.must_equal "222-3333"
  end

  it "returns false from valid? if a validation fails on the first record" do
    @house_listing_form.street_number = nil
    @house_listing_form.valid?.must_equal false
  end

  it "returns false from valid? if a validation fails on the last record" do
    @house_listing_form.name = nil
    @house_listing_form.valid?.must_equal false
  end

  it "applies changes to all models in memory, but rolls back all saves if the first fails validation" do
    proc { @house_listing_form.update!(:street_name => "Small Street", :phone_number => "222-3333", :street_number => nil) }.must_raise ActiveRecord::RecordInvalid

    @house.street_number.must_equal nil
    @house.street_name.must_equal "Small Street"
    @vendor.phone_number.must_equal "222-3333"

    @house.reload.street_number.must_equal "8/90"
    @house.reload.street_name.must_equal "Main Street"
    @vendor.reload.phone_number.must_equal "123-4567"
  end

  it "applies changes to all models in memory, but rolls back all saves if the second fails validation" do
    proc { @house_listing_form.update!(:street_name => "Small Street", :phone_number => "222-3333", :name => nil) }.must_raise ActiveRecord::RecordInvalid

    @house.street_name.must_equal "Small Street"
    @vendor.phone_number.must_equal "222-3333"
    @vendor.name.must_equal nil

    @house.reload.street_name.must_equal "Main Street"
    @vendor.reload.phone_number.must_equal "123-4567"
    @vendor.name.must_equal "Test User"
  end

  it "supports delegation for accessing related records" do
    @house_listing_form = DelegatedHouseListingForm.new(@house)
    @house_listing_form.update!(:street_name => "Small Street", :phone_number => "222-3333")
    @house.reload.street_name.must_equal "Small Street"
    @vendor.reload.phone_number.must_equal "222-3333"
  end
end
