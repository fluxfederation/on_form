Changelog
=========

3.1.3
* Fix issue in Collection Wrapper which was still using deprecated Rails functionality

3.1.2
* Fix Ruby 3 deprecations

3.1.1
* Make Gem compatible with Rails 6.1

3.1.0
-----
* Support `reject_if` option on `expose_collection_of`.  Thanks @Dhamsoft.

3.0.0
-----
* Support `save(validate: false)` and `save!(validate: false)`.
* Change callback order to better match ActiveRecord: validation callbacks fire before `before_save` fires, and model callbacks fire before the form's `after_validation` callback fires.
* Collect errors from collection forms and present them on the form itself.  Thanks @Dhamsoft.

2.3.0
-----
* Add `take_identity_from` to improve interoperability with standard resource ('RESTful') controllers and form helpers.

2.2.2
-----
* Support non-array argument to `expose`.
* Fix compatibility with `ActionController::Parameters`.

2.2.1
-----
* Fill in the validation error message for Rails 4.2.

2.2.0
-----
* Remove the previously existing transaction caveat around model-less saves.

2.1.0
-----
* Implement support for introducing typed "artificial" attributes.

2.0.1
-----
* Fix regressions in support for Rails 4.2.
* Support some additional attribute methods such as `*_was` and `*_changed?`.

2.0.0
-----
* New expose syntax to support prefix:, suffix:, and as: options.

1.0.0
-----
* First public release.
