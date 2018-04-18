# OnForm

A pragmatism-first library to help Rails applications migrate from complex nested attribute models to tidy form objects.

Our goal is that you can migrate large forms to OnForm incrementally, without having to refactor large amounts of code in a single release.

Data and validations flow back and forward from the model layer automatically once you've defined which model attributes should be exposed.

Forms backed by multiple models are supported natively, with no concept of a single main model.

ActiveModel/ActiveRecord idioms such as validations and callbacks can be used directly in the form object.

Whereever possible, the terminology and experience should be familiar to Rails developers, to minimize relearning time.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'on_form', '~> 1.0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install on_form

## Usage

This version of OnForm should work with Rails 5.0 and 4.2.

This version of OnForm depends on both the `activemodel` and `activerecord` gems.  Rails 5.0 has refactored some of the necessary ActiveRecord code across to ActiveModel, so the `activerecord` dependency may be dropped once Rails 4.2 support is dropped.

### Simple example of wrapping a model

Let's say you have a big fat legacy model called `Customer`, and you have a preferences controller:

```ruby
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
```

Let's wrap the customer object in a form object.  Ideally we'd call this `@customer_form`, but you may not feel you have time to go and update all your view code, so in this example we'll keep calling it `@customer`.

```ruby
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
```

Now we need to make our form object.  At this point we need to tell the form object which attributes on the model we want to `expose`.  (In this example we have just one model and a couple of attributes, but you wouldn't bother using this library if this was all you had.)

```ruby
class PreferencesForm < OnForm::Form
  expose %i(name email phone_number), on: :customer

  def initialize(customer)
    @customer = customer
  end
end
```

The form object responds to the usual persistance methods like `email`, `email=`, `save`, `save!`, `update`, and `update!`.  

It will automatically write those exposed attributes back onto the models, and *it exposes any validation errors from those fields on the form object itself* - you don't have to copy them back manually or move your field validation code over to get started.  It'll also expose any errors on base on the models whose attributes you exposed.  See the Validations section below for more.

### A multi-model form

You aren't limited to having one primary model - if your form is backed by multiple models just call `expose` for each one.  They'll automatically be saved in the same order you declared them.

In this example, the new models we're exposing are associated with the first one, so we don't need to pass them in to the constructor.

```ruby
class HouseListingForm < OnForm::Form
  expose %i(street_number street_name city), on: :house
  expose %i(name phone_number), on: :vendor

  def initialize(house)
    @house = house
    @vendor = house.vendor
  end
end
```

Transactions will automatically be started so that _all_ database updates will be rolled back if _any_ record fails to save (for example, due to a validation error).

Note that the `on:` kwarg gives the name of the method on the form object which returns the record - nothing to do with class names.  In this example, vendor might actually be an instance of our `Customer` model from the earlier examples.

### Model accessor methods

In the previous example, the constructor set `@house` and `@vendor` because these variables correspond to the name passed to `expose` in the `on` option.  `expose` will automatically add an `attr_reader` for this name, meaning you only need to set the instance variables.

But if you prefer, you can define a method with the same name yourself, for example using delegation.  `expose` won't run `attr_reader` if you've already defined the method, and there's no requirement to set an instance variable.

```ruby
class HouseListingForm < OnForm::Form
  delegate :vendor, :to => :house

  expose %i(street_number street_name city), on: :house
  expose %i(name phone_number), on: :vendor

  def initialize(house)
    @house = house
  end
end
```

You can also define your own method over the top of the `attr_reader`.  Just remember it will be called more than once, so it must be idempotent.

### View helpers & acting like ActiveModel/ActiveRecord

Since OnForm doesn't require a single "main" model, forms don't automatically have any particular identity value (ie. an `id` attribute or a value to return from `to_param`).

So although by default forms will work fine with all the 'raw' form field helpers and with helpers like `fields_for`, they're not automatically usable with the resource form methods like `form_for`, which assumes you have a one-to-one correspondance between your models and your views (in other words, that you have no form object layer).

You have several options.  First, you can start your form tags completely manually, optionally choosing the name for the params:

```erb
<%= form_tag customer_path(edit_details_form.customer), method: :put do %>
  <%# if the controller has set an ivar called @edit_details_form %>
  <%= fields_for :edit_details_form do |f| %>
    <%# produces a field called edit_details_form[name] %>
    <%= f.text_field :name %>
  <% end %>

  <%# or you can give it a different name, to control what the form params will be named %>
  <%= fields_for :customer, @edit_details_form do |f| %>
    <%# produces a field called customer[name], which is what a normal resource controller expects %>
    <%= f.text_field :name %>
  <% end %>
<% end %>
```

Secondly, you can combine these calls into a `form_for` call using some of its optional arguments:

```erb
<%= form_for @edit_details_form, as: :customer, url: customer_path(edit_details_form.customer), method: :put do |f| %>
  <%# produces a field called customer[name] %>
  <%= f.text_field :name %>
<% end %>
```

Thirdly, you can delegate the identity question to one of the models that backs the form using `takes_identity_from`.  When you do this, the form objects start to return that model from `to_model` and the `to_key` and `to_param` values of that model as their own.  This is the recommended approach when dealing with standard resource ('RESTful') controllers.

```ruby
class EditPostForm < OnForm::Form
  take_identity_from :post

  expose %i(title body), on: :post

  def initialize(post)
    @post = post
  end
end
```

```erb
<%= form_for @edit_details_form do |f| %>
  <%# produces a field called customer[name] %>
  <%= f.text_field :name %>
<% end %>
```

Note that we no longer have to specify the `as` ,`url`, or `method` options, because these will be automatically derived from the `customer` model instead of from the form object itself.

When you choose an identity model, it will also become the default model for `expose` calls, which helps DRY up single-model form objects.

```ruby
class EditPostForm < OnForm::Form
  take_identity_from :post

  expose %i(title body)

  def initialize(post)
    @post = post
  end
end
```

### Renaming attributes

By default the attribute names exposed on the form object are the same as the attributes on the backing models.  Sometimes this leads to unclear meanings, and sometimes you'll have duplicate attribute names in a multi-model form.

To address this you can use the `prefix` and/or `suffix` options to `expose`, or if you need to change the name completely, the `as` option.

```ruby
class AccountHolderForm < OnForm::Form
  expose %i(name date_of_birth), on: :customer, prefix: "account_holder_"
  expose %i(email), on: :customer, suffix: "_for_billing"
  expose %i(phone_number), on: :customer, as: "mobile_number"

  def initialize(customer)
    @customer = customer
  end
end
```

This is especially useful if you like to use helpers like `error_messages_on` which will "humanize" the attribute names and use them in the human-readable page.

Try to use this only when it makes the attribute names more meaningful.  In particular, automatically renaming all of your attributes with a prefix matching the backing model is considered a bad habit because it leads to unnecessary coupling between the views and the current backing data model schema.

### Validations

Validations on the underlying models not only get used, but their validation errors show up on the form's `errors` object directly when you call `valid?` or any of the save/update methods.

But you can also declare validations on the form object itself, which is useful when you have business rules applicable to this form that aren't intrinsic to the domain model.

```ruby
class AddEmergencyContactForm < OnForm::Form
  expose %i(next_of_kin_name next_of_kin_phone_number), on: :customer

  validates_presence_of :next_of_kin_name, :next_of_kin_phone_number

  def initialize(customer)
    @customer = customer
  end
end
```

Note that when you call `save!`, `update!`, or `update_attributes!` on the form object, validation errors from records will still raise `ActiveRecord::RecordInvalid`, but validation errors from validations defined on the form itself will raise `ActiveModel::ValidationError`.  You will usually want to rescue both.

### Callbacks

You can also use the `before_validation`, `before_save`, `after_save`, and `around_save` validations.  Like ActiveRecord, these will run inside the database transaction when you're calling one of the save or update methods, which is especially useful if you need to take locks on parent records.

```ruby
class NewBranchForm < OnForm::Form
  expose %w(bank_id branch_number branch_name), on: :branch

  before_save :lock_bank

protected
  def lock_bank
    branch.bank.lock!
  end
end
```

Model validations and validation callbacks occur between the form validation before and after callbacks, and model save calls are nested inside the form save calls, but the save calls all follow the validations and validation callbacks.

    form before_validation
    model before_validation
    model validate (validations defined on the model)
    model after_validation
    form validate (validations defined on the form itself)
    form after_validation
    form before_save
    form around_save begins
      model before_save
      model around_save begins
        model saved
      model around_save ends
      model after_save
    form around_save ends
    form after_save

### Adding artifical attributes

In addition to mapping attributes between models and the form, you can introduce new attributes which are not directly persisted anywhere.  You can use any of the "standard" (non-database-specific) ActiveRecord types, and you can add `default`, `scale`, and `precision` options.

```ruby
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
```

### Model-less forms

Taking this one step further, you can define forms which have _no_ exposed model attributes.

To actually perform a data change in response to the form submission, you can add a `before_save` or `after_save` callback and from there call your existing model code or service objects.  It's best to keep the code in the form object to just the bits specific to the form - try not to put your business logic in your form objects!

```ruby
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
    unless @customer.password_correct?(current_password)
      errors[:current_password] << "is incorrect"
    end
  end

  def password_confirmation_matches
    unless password_confirmation == password
      errors[:password_confirmation] << "doesn't match"
    end
  end

  def set_new_password
    @customer.change_password!(password)
  end
end
```

Note that when you have no exposed models, OnForm will still wrap the save process in a database transaction for you, using `ActiveRecord::Base.transaction`.  If you have multiple database connections, you may need to start transactions on the other connections yourself.

### Reusing and extending forms

You can descend form classes from other form classes and expose additional models or additional attributes on existing models.

```ruby
class AdminHouseListingForm < HouseListingForm
  expose %i(listing_approved), on: :house
end
```

This works well for some use cases, but can quickly become cumbersome if you have a lot of partial form reuse, and it may not be obvious to other developers that the parent form is also used to derive the other forms.  Consider breaking your form parts into reuseable modules, and defining each form separately.

You can use standard Ruby hooks for this:

```ruby
module AccountFormComponent
  def self.included(form)
    form.expose %i(email phone_number), on: :customer
  end
end

class NewAccountForm < OnForm::Form
  include AccountFormComponent

  expose %i(name), on: :customer

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
```

In this example the initialize method could actually be moved to the module as well, but that makes it harder to compose forms from multiple modules.

If you prefer, you can use the Rails `included` block syntax in the module instead of `def self.included`.

## Development

After checking out the repo, pick the rails version you'd like to run tests against, and run:

    RAILS_VERSION=5.0.0.1 bundle update

You should then be able to run the test suite:

    bundle exec rake

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powershop/on_form.

## Roadmap

* The author is currently assessing other use cases for ActiveRecord nested attributes, such as one-to-many associations and auto-building/deleting associated records.  Feedback welcome.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

Copyright &copy; Powershop New Zealand Limited, 2016
