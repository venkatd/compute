# Compute

Compute is like Excel for your ActiveRecord models.
It lets you define computed attributes stored that get stored the database.

The main benefits are
- Performance: computed columns are only updated when the values they depend on change
- Querying: you can now easy include these columns in your queries

Here are some sample use cases
- Having an field which depends on the users birthday. Now you can easily query on age instead of having custom SQL.
- An SHA1 hash that gets updated when the a file path changes
- A bill could have tax, tip, and total which all depend on subtotal
- Having a city and state column get computed from longitude and latitude (using the Google Geocoding API)

## Installation

Add this line to your application's Gemfile:

    gem 'compute'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install compute

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
