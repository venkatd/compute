require 'spec_helper'

describe Compute do

  with_model :User do
    table do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :first_initial
      t.string :initials
      t.timestamps
    end

    model do
      include Compute

      compute :first_initial do |first_name|
        first_name[0]
      end

      compute :full_name do |first_name, last_name|
        "#{first_name} #{last_name}"
      end

    end

  end

  with_model :Bill do
    table do |t|
      t.integer :subtotal
      t.integer :tax
      t.integer :tip
      t.integer :total
    end

    model do
      include Compute

      # total is put first to ensure dependency tracker correctly sorts
      compute :total do |subtotal, tax, tip|
        subtotal + tax + tip
      end

      compute :tax do |subtotal|
        (subtotal * 0.05).to_i
      end

      compute :tip do |subtotal|
        (subtotal * 0.15).to_i
      end
    end
  end

  it "should work when updated as a field" do
    u = User.new
    u.first_name = "George"
    u.save

    u.first_initial.should == 'G'
  end

  it "should work when added in the constructor" do
    u = User.create(first_name: "Wally")
    u.first_initial.should == 'W'
  end

  it "should allow multiple sources for a computed field" do
    u = User.create(first_name: "John", last_name: "Doe")
    u.full_name.should == "John Doe"
  end

  it "should update the computed field if even one of the values changes" do
    u = User.create(first_name: "John", last_name: "Doe")

    u.first_name = "Bob"
    u.save
    u.full_name.should == "Bob Doe"

    u.last_name = "Schmoe"
    u.save
    u.full_name.should == "Bob Schmoe"
  end

  it "should take dependencies into consideration" do
    restaurant_bill = Bill.create(subtotal: 100)
    restaurant_bill.tax.should == 5
    restaurant_bill.tip.should == 15
    restaurant_bill.total.should == 120
  end

end
