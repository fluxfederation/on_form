# OnForm

A pragmatism-first library to help Rails applications migrate from complex nested attribute models to tidy form objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'on_form'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install on_form

## Usage

### Simple example of wrapping a model

Let's say you have a big fat legacy model called `Customer`, and you have a preferences controller:

	class PreferencesController
	  def show
	    @customer = Customer.find(params[:id])
	  end

	  def update
	    @customer = Customer.find(params[:id])
	    @customer.update!(params[:customer].permit(:name, :email, :phone_number)
	    redirect_to preferences_path(@customer)
	  rescue ActiveRecord::RecordInvalid
	    render :show
	  end
	end

Let's wrap the customer object in a form object.  Ideally we'd call this `@customer_form`, but you may not feel you have time to go and update all your view code, so in this example we'll keep calling it `@customer`.

	class PreferencesController
	  def show
	    @customer = PreferencesForm.new(Customer.find(params[:id]))
	  end

	  def update
	    @customer = PreferencesForm.new(Customer.find(params[:id]))
	    @customer.update!(params[:customer])
	  rescue ActiveRecord::RecordInvalid
	    render :show
	  end
	end

Now we need to make our form object.  At this point we need to tell the form object which attributes on the model we want to expose.  (In this example we have just one model and a couple of attributes, but you wouldn't bother using this library if this was all you had.)

	class PreferencesForm < OnForm::Form
	  expose :customer => %i(name email phone_number)

	  def initialize(customer)
	    @customer = customer
	  end
	end

The form object responds to the usual persistance methods like `email`, `email=`, `save`, `save!`, `update`, and `update!`.  

It will automatically write those exposed attributes back onto the models, and *it exposes any validation errors from those fields on the form object itself* - you don't have to copy them back manually or move your field validation code over to get started.  It'll also expose any errors on base on the models whose attributes you exposed.

### A multi-model form

You aren't limited to having one primary model - if your form is made up of multiple models pass more than one key to `expose`, or call it multiple times if you prefer.  They'll automatically be saved in the same order you declared them.

In this example, the new models we're exposing are associated with the first one, so we don't need to pass them in to the constructor.

	class HouseListingForm < OnForm::Form
	  expose :house => %i(street_number street_name city),
	         :vendor => %i(name phone_number)

	  def initialize(house)
	    @house = house
	    @vendor = house.vendor
	  end
	end

Transactions will automatically be started so that _all_ database updates will be rolled back if _any_ record fails to save (for example, due to a validation error).

Note that the keys are the name of the methods on the form object which return the records, not the class names.  In this example, vendor might actually be an instance of our `Customer` model from the earlier examples.

### Model accessor methods

In the previous example, the constructor set `@house` and `@vendor` because these variables correspond to the names passed to `expose`.  `expose` will automatically add an `attr_reader` for each key it's given, meaning you only need to set the instance variables.

But if you prefer, you can define a method with the same name yourself, for example using delegation.  `expose` won't run `attr_reader` if you've already defined the method, and there's no requirement to set an instance variable.

	class HouseListingForm < OnForm::Form
	  delegate :vendor, :to => :house

	  expose :house => %i(street_number street_name city),
	         :vendor => %i(name phone_number)

	  def initialize(house)
	    @house = house
	  end
	end

You can also define your own method over the top of the `attr_reader`.  Just remember it will be called more than once, so it should be idempotent.

### Validations

Validations on the underlying models not only get used, but their validation errors show up on the form's `errors` object directly when you call `valid?` or any of the save/update methods.

But you can also declare validations on the form object itself, which is useful when you have business rules applicable to this form that aren't intrinsic to the domain model.

	class AddEmergencyContactForm < OnForm::Form
	  expose :customer => %i(next_of_kin_name next_of_kin_phone_number)

	  validates_presence_of :next_of_kin_name, :next_of_kin_phone_number

	  def initialize(customer)
	    @customer = customer
	  end
	end

### Callbacks

You can also use the `before_validation`, `before_save`, `after_save`, and `around_save` validations.  Like ActiveRecord, these will run inside the database transaction when you're calling one of the save or update methods, which is especially useful if you need to take locks on parent records.

	class NewBranchForm < OnForm::Form
	  expose :branch => %w(bank_id branch_number branch_name)

	  before_save :lock_bank

	protected
	  def lock_bank
	    branch.bank.lock!
      end
	end

Note that model save calls are nested inside the form save calls, which means that although form validation takes place before form save starts, model validation takes place after form saving begins.

    form before_validation
    form validate (validations defined on the form itself)
    form before_save
    form around_save begins
      model before_validation
      model validate (validations defined on the model)
      model before_save
      model around_save begins
        model saved
      model around_save ends
      model after_save
    form around_save ends
    form after_save

### Reusing and extending forms

You can descend form classes from other form classes and expose additional models or additional attributes on existing models.

	class AdminHouseListingForm < HouseListingForm
	  expose :house => %i(listing_approved)
	end

This works well for some use cases, but can quickly become cumbersome if you have a lot of partial form reuse, and it may not be obvious to other developers that the parent form is also used to derive the other forms.  Consider breaking your form parts into reuseable modules, and defining each form separately.

You can use standard Ruby hooks for this:

	module AccountFormComponent
	  def self.included(form)
	    form.expose :customer => %i(email phone_number)
	  end
	end

	class NewAccountForm < OnForm::Form
	  include AccountFormComponent

	  expose :customer => %i(name)

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

In this example the initialize method could actually be moved to the module as well, but that makes it harder to compose forms from multiple modules.

If you prefer, you can use the Rails `included` block syntax in the module instead of `def self.included`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powershop/on_form.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright &copy; Powershop New Zealand Limited, 2016
