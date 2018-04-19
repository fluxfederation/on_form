require "test_helper"

class RoomListingForm < OnForm::Form
  expose %i(street_number street_name city), on: :house

  expose_collection_of :house_rooms, on: :house, as: :rooms, allow_insert: true, allow_update: true, allow_destroy: true do
    expose :name, as: :room_name
    expose :area
    validates :room_name, length: { maximum: 100, too_long: "%{count} characters is the maximum allowed" }
  end

  def initialize(house)
    @house = house
  end
end

describe "forms including has_many collections" do
  before do
    Customer.delete_all
    House.delete_all
    @vendor = Customer.create!(name: "Test User", email: "test@example.com", phone_number: "123-4567")
    @house = House.create!(:vendor => @vendor, :street_number => "8/90", :street_name => "Main Street", :city => "Townsville")
    @rooms = [
      @house.house_rooms.create!(:name => "Bedroom", :area => 20),
      @house.house_rooms.create!(:name => "Bathroom", :area => 16),
    ]
    @room_listing_form = RoomListingForm.new(@house)
  end

  it "exposes the form wrappers under the exposed name of the collection" do
    rooms = @room_listing_form.rooms.to_a
    rooms.size.must_equal 2
    rooms.first.must_be_instance_of RoomListingForm::RoomForm
    rooms.last.must_be_instance_of RoomListingForm::RoomForm
    rooms.first.room_name.must_equal "Bedroom"
    rooms.last.room_name.must_equal "Bathroom"
    rooms.first.room_name = "Master bedroom"
    @room_listing_form.save
    @rooms.first.reload.name.must_equal "Master bedroom"
  end

  it "caches the wrapped forms so they can be iterated over multiple times" do
    rooms1 = @room_listing_form.rooms.to_a
    rooms2 = @room_listing_form.rooms.to_a
    rooms1.collect(&:object_id).must_equal rooms2.collect(&:object_id)
    @room_listing_form.rooms.each { |room| rooms1.must_include room }
  end

  it "allows updates with no mention of child records" do
    @room_listing_form.update!(:city => "Fancyville")
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 2
  end

  it "allows updates to child records identified by ID" do
    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { :id => @rooms.last.id, :room_name => "Kitchen" },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 2
    @rooms.last.reload.name.must_equal "Kitchen"

    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { "id" => @rooms.first.id.to_s, "room_name" => "Lounge" },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 2
    @rooms.first.reload.name.must_equal "Lounge"
  end

  it "allows creation of new child records" do
    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { :room_name => "Kitchen", :area => 12 },
      { "room_name" => "Lounge", "area" => 24 },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 4
    room = @house.house_rooms.order(:id).last
    room.name.must_equal "Lounge"
    room.area.must_equal 24
  end

  it "doesn't add new child records already marked for destruction" do
    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { :room_name => "Kitchen", :area => 12, :_destroy => true },
      { "room_name" => "Lounge", "area" => 24, "_destroy" => "1" },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 2
    @house.house_rooms.to_a.must_equal @rooms
  end

  it "allows destruction of child records" do
    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { :id => @rooms.last.id, :_destroy => true },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 1
    @rooms.first.reload
    proc { @rooms.last.reload}.must_raise ActiveRecord::RecordNotFound

    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => [
      { "id" => @rooms.first.id.to_s, "_destroy" => "true" },
    ])
    @house.reload.city.must_equal "Fancyville"
    @house.house_rooms.size.must_equal 0
    proc { @rooms.first.reload}.must_raise ActiveRecord::RecordNotFound
  end

  it "accepts hash syntax for records" do
    @room_listing_form.update!(:city => "Fancyville", :rooms_attributes => {
      @rooms.first.id.to_s => { "id" => @rooms.last.id.to_s, "room_name" => "Lounge", :area => 9 },
      "0" => { "room_name" => "Kitchen", "area" => 18 },
    })
    @house.reload.city.must_equal "Fancyville"

    # Update existing record
    @house.house_rooms.size.must_equal 3
    @rooms.last.reload.name.must_equal "Lounge"
    @rooms.last.area.must_equal 9

    # Create new record
    room = @house.house_rooms.order(:id).last
    room.name.must_equal "Kitchen"
    room.area.must_equal 18
  end

  it "returns false from valid? if a validation fails on the child records" do
      proc do
        @room_listing_form.update!(
          :rooms_attributes => {
            @rooms.first.id.to_s => { "id" => @rooms.first.id.to_s, "room_name" => "", :area => 9 }
          }
        )
      end.must_raise ActiveModel::ValidationError

      @room_listing_form.valid?.must_equal false
      @room_listing_form.errors['rooms.room_name'].must_equal ["can't be blank"]
  end

  it "returns false from valid? if a validation fails on the child form validation" do
    @room_listing_form.attributes= {
      :rooms_attributes => {
        @rooms.first.id.to_s => { "id" => @rooms.first.id.to_s, "room_name" => "x"*101, :area => 9 }
      }
    }

    @room_listing_form.valid?.must_equal false
    @room_listing_form.errors['rooms.room_name'].must_equal ["100 characters is the maximum allowed"]
  end

  it "returns the assigned instances from the association-like method for redisplay even if the form hasn't been saved" do
    @room_listing_form.attributes = { :city => "Fancyville", :rooms_attributes => [
      { :id => @rooms.first.id, :room_name => "Master bedroom" },
      { :id => @rooms.last.id, :_destroy => true },
      { :room_name => "Kitchen", :area => 12 },
      { "room_name" => "Lounge", "area" => 24 },
    ] }
    @room_listing_form.rooms.size.must_equal 4
    @room_listing_form.rooms.collect(&:room_name).must_equal ["Master bedroom", "Bathroom", "Kitchen", "Lounge"]
    @room_listing_form.rooms[1].marked_for_destruction?.must_equal true
  end

  it "applies updates to the backing records and adds them to the association so that if autosave is enabled on the association they are updated even if the forms themselves are not saved" do
    # this test shows why we have the add_to_target call in parse_collection_attributes.
    # unfortunately, to show this effect we need autosave on, and we didn't want to rely
    # on it being on to make the form class itself save correctly, so we haven't turned
    # it on in House.has_many :rooms.  we turn it on here temporarily.
    autosave = House._reflect_on_association(:house_rooms).options[:autosave]
    begin
      House._reflect_on_association(:house_rooms).autosave = true
      @room_listing_form.attributes = { :city => "Fancyville", :rooms_attributes => [
        { :id => @rooms.last.id, :room_name => "Kitchen" },
      ] }
      @house.save! # rather than @room_listing_form.save!
      @house.reload.city.must_equal "Fancyville"
      @house.house_rooms.size.must_equal 2
      @rooms.last.reload.name.must_equal "Kitchen"
    ensure
      House._reflect_on_association(:house_rooms).options[:autosave] = autosave
    end
  end

  it "doesn't touch the autosave setting on the association by default, nor rely on it being on to pass the other tests" do
    # see comment in the previous test for the significance of this setting.
    House._reflect_on_association(:house_rooms).options[:autosave].must_equal nil
  end
end
