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

The compute method accepts a block. 
The names of the arguments in the block MUST match up with the properties of the model.
The following example keeps the user.age column in sync with the user.time column. 

```
class User < ActiveRecord::Base

  compute :age do |birthday|
    unless birthday.blank?
      now = Time.now.utc.to_date
      now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
    end
  end

end
```

The compute method accepts multiple arguments. Computations are also run in the correct order.
In the block, self will be set to the model instance.
In the following example, total will be calculated after tax and tip are calculated. Again, think of it like Excel!

```
class User < ActiveRecord::Base

  compute :age do |birthday|
    unless birthday.blank?
      now = Time.now.utc.to_date
      now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
    end
  end

end

class RestaurantBill < ActiveRecord::Base

  compute(:date) { |created_at| created_at.to_date }

  compute :total do |tax, tip|
    tax + tip
  end

  compute :tax do |subtotal|
    subtotal * tax_rate
  end

  compute :tip do |subtotal|
    subtotal * tip_rate
  end

  def tax_rate
    0.08
  end

  def tip_rate
    0.15
  end

end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
