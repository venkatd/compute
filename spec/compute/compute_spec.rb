require 'spec_helper'

describe Compute do

  with_model :User do
    table do |t|
      t.string :first_name
      t.string :last_name
      t.string :full_name
      t.string :first_initial
      t.string :initials
      t.date :date
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

      compute :date do |created_at|
        created_at.to_date
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

  with_model :ModelWithCycles do

    table do |t|
      t.integer :a
      t.integer :b
    end

    model do
      include Compute
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

  it "should work with timestamps" do
    u = User.create(first_name: "John", last_name: "Doe")
    u.created_at.should_not be_nil
    u.date.should_not be_nil
  end

  it "should raise a CyclicComputation error when there is a circular dependency" do
    expect do
      class ModelWithCycles
        compute(:a) { |b| b * 2 }
        compute(:b) { |a| a / 2 }
      end
    end.to raise_error(Compute::CyclicComputation)
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

  it "should update dependent fields when a field is updated" do
    bill = Bill.create(subtotal: 100)

    bill.update_attributes(subtotal: 200)

    bill.tax.should == 10
    bill.tip.should == 30
    bill.total.should == 240
  end

  describe "recompute!" do

    it "should only recompute the specified field" do
      bill = Bill.create(subtotal: 100)
      [:tax, :tip, :total].each { |c| bill.update_column(c, 0) }

      bill.recompute!(:tax)
      bill.tax.should == 5
      bill.tip.should == 0
      bill.total.should == 105
    end

    it "should work with multiple fields regardless of order" do
      bill = Bill.create(subtotal: 100)
      [:tax, :tip, :total].each { |c| bill.update_column(c, 0) }

      bill.tax.should == 0
      bill.tip.should == 0
      bill.total.should == 0

      bill.recompute!(:total, :tax, :tip)
      bill.tax.should == 5
      bill.tip.should == 15
      bill.total.should == 120
    end

    it "should work with an array" do
      bill = Bill.create(subtotal: 100)
      [:tax, :tip, :total].each { |c| bill.update_column(c, 0) }

      bill.recompute!([:tax, :tip])
      bill.tax.should == 5
      bill.tip.should == 15
    end

    it "should propagate all changes" do
      bill = Bill.create(subtotal: 100)
      bill.update_column(:subtotal, 200)

      bill.recompute!
      bill.tax.should == 10
      bill.tip.should == 30
      bill.total.should == 240
    end

    it "should work on multiple records for all columns" do
      bill1 = Bill.create(subtotal: 100)
      bill1.update_column(:tax, 0)
      bill1.update_column(:tip, 0)

      bill2 = Bill.create(subtotal: 200)
      bill2.update_column(:tax, 0)
      bill2.update_column(:tip, 0)

      Bill.recompute!
      bill1.reload
      bill2.reload

      bill1.tip.should == 15
      bill2.tip.should == 30

      bill1.tax.should == 5
      bill2.tax.should == 10
    end

    it "should work on multiple records for specific columns" do
      bill1 = Bill.create(subtotal: 100)
      bill1.update_column(:tax, 0)
      bill1.update_column(:tip, 0)

      bill2 = Bill.create(subtotal: 200)
      bill2.update_column(:tax, 0)
      bill2.update_column(:tip, 0)

      Bill.recompute!(:tip)
      bill1.reload
      bill2.reload

      bill1.tip.should == 15
      bill2.tip.should == 30

      bill1.tax.should == 0
      bill2.tax.should == 0
    end

    it "should work on an ActiveRecord relation" do
      bill1 = Bill.create(subtotal: 100)
      bill1.update_column(:tax, 0)
      bill1.update_column(:tip, 0)

      bill2 = Bill.create(subtotal: 200)
      bill2.update_column(:tax, 0)
      bill2.update_column(:tip, 0)

      Bill.where(id: [bill1.id, bill2.id]).recompute!(:tip)
      bill1.reload
      bill2.reload

      bill1.tip.should == 15
      bill2.tip.should == 30

      bill1.tax.should == 0
      bill2.tax.should == 0
    end

    it "should let you overwrite previous computation rules" do
      Bill.compute :tip do |subtotal|
        subtotal + 50
      end

      bill = Bill.create(subtotal: 100)
      bill.tip.should == 150
      bill.tax.should == 5
      bill.total.should == 255

      Bill.compute :tip do |subtotal|
        subtotal * 0.15
      end
    end

  end


end
