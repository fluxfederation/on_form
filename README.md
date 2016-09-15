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

### Start by wrapping one model

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

Now we need to make our form object.  At this point we need to tell the form object which attributes on the model we want to expose.  (I'm just going to put a couple in here, but you wouldn't bother using this library if this was all you had.)

	class PreferencesForm < OnForm::Form
	  attr_reader :customer

	  expose :customer => %i(name email phone_number)

	  def initialize(customer)
	    @customer = customer
	  end
	end

The form object responds to the usual persistance methods like `email`, `email=`, `save`, `save!`, `update`, and `update!`.  

It will automatically write those exposed attributes back onto the models, and *it exposes any validation errors from those fields on the form object itself* - you don't have to copy them back manually or move your field validation code over to get started.  It'll also expose any errors on base on the models whose attributes you exposed.

### A multi-model form

You aren't limited to having one primary model - if your form is made up of multiple models pass more than one key to `expose`, or call it multiple times if you prefer.  They'll automatically be saved in the same order you declared them.

In this example, the new models we're exposing are associated with the first one, so we don't need to pass them in to the constructor:

	class HouseListingForm < OnForm::Form
	  attr_reader :house, :vendor

	  expose :house => %i(street_number street_address city),
	         :vendor => %i(name phone_number)

	  def initialize(house, :vendor)
	    @house = house
	    @vendor = house.vendor
	  end
	end

Transactions will automatically be started so that _all_ database updates will be rolled back if _any_ record fails to save (for example, due to a validation error).

Note that the keys are the name of the methods on the form object which return the records, not the class names.  In this example, vendor might actually be an instance of our `Customer` model from the earlier examples.  You might also prefer to use `delegate` rather than setting up `attr_reader` and initialising in the form object constructor - up to you.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powershop/on_form.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

