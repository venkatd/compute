module Compute

  class Computation

    def initialize(model, property, &block)
      @model = model
      @property = property
      @proc = Proc.new(&block)
      @source_properties = extract_parameter_names(@proc)
    end

    def property
      @property
    end

    def needs_update?(record)
      common_changes = record.changed.map(&:to_sym) & @source_properties
      common_changes.count > 0
    end

    def update(record)
      source_values = source_values(record)
      destination_result = @proc.call(*source_values)
      record.send(@property.to_s + '=', destination_result)
    end

    private

    def extract_parameter_names(proc)
      proc.parameters.map { |arg| arg[1] }
    end

    def source_values(record)
      @source_properties.map { |property| record.send(property) }
    end

  end

  module ClassMethods

    def compute(property, &block)
      computations << Computation.new(self, property, &block)
    end

    def computations
      @computations ||= []
    end

  end

  # here base is a class the module is included into
  def self.included(base)
    # extend includes all methods of the module as class methods
    # into the target class
    base.extend ClassMethods
    base.class_eval do
      before_save :computed_fields_update_all
    end
  end

  def recompute!(property = nil)
    property = property.to_sym
    self.class.computations.each do |computation|
      if property.nil? || computation.property == property
        computation.update(self)
      end
    end
    save
  end

  private

  def computed_fields_update_all
    self.class.computations.each do |computation|
      if computation.needs_update?(self)
        computation.update(self)
      end
    end
  end

end
