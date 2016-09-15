# Formulaic

A pragmatism-first library to help Rails applications migrate from complex nested attribute models to tidy form objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'formulaic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install formulaic

## Usage

### Start by wrapping one model

Let's say you have a big fat legacy model called `Customer`, and you have a preferences controller:

	class PreferencesController
	  def show
	    @customer = Customer.find(params[:id])
	  end

	  def update
	    @customer = Customer.find(params[:id])
	    @customer.update!(params[:customer])
	    redirect_to preferences_path(@customer)
	  rescue ActiveRecord::RecordInvalid
	    render :show
	  end
	end

Let's wrap the customer object in a form object.  Ideally we'd call this @customer_form, but you may not feel you have time to go and update all your views yet, so in this example we'll keep calling it @customer.

	class PreferencesController
	  def show
	    @customer = CustomerForm.new(Customer.find(params[:id]))
	  end

	  def update
	    @customer = CustomerForm.new(Customer.find(params[:id]))
	    @customer.update!(params[:customer])
	  rescue ActiveRecord::RecordInvalid
	    render :show
	  end
	end

Now we need to make our form object.  At this point we need to tell the form object which attributes on the model we want to expose.  (I'm just going to put a couple in here, but you wouldn't bother using this library if this was all you had.)

	class CustomerForm < Formulaic::Form
	  attr_reader :customer

	  expose :customer => %i(name email phone_number)

	  def initialize(customer)
	    @customer = customer
	  end
	end

The form object responds to the usual persistance methods like `email`, `email=`, `save`, `save!`, `update`, and `update!`.  

It will automatically write those exposed attributes back onto the models, and *it exposes any validation errors from those fields on the form object itself* - you don't have to copy them back manually or move your field validation code over to get started.  It'll also expose any errors on base on the models whose attributes you exposed.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powershop/formulaic.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

