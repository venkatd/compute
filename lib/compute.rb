require "compute/version"
require "compute/railtie" if defined? Rails

require 'tsort'

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

    def dependencies
      @source_properties
    end

    def needs_update?(changed_properties)
      common_changes = changed_properties.map(&:to_sym) & @source_properties
      common_changes.count > 0
    end

    def apply(record)
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

  class ComputationSet < Hash
    include TSort

    def initialize
      @computations_for_changed_properties = Hash.new do |h, changed_properties|
        @sorted_computations.select { |c| c.needs_update?(changed_properties) }
      end
    end

    def tsort_each_node
      each do |property, computation|
        yield computation.property
      end
    end

    def tsort_each_child(property)
      if self.has_key?(property)
        self[property].dependencies.each { |p| yield p }
      end
    end

    def <<(computation)
      self[computation.property] = computation
      sort!
    end

    def sort!
      @sorted_computations = tsort.map { |p| self[p] }.compact
    end

    def each_in_order
      @sorted_computations.each { |c| yield c }
    end

    def for_property(property)
      self[property.to_sym]
    end

    def for_changed_properties(changed_properties)
      @computations_for_changed_properties[changed_properties]
    end

  end

  module ClassMethods

    def compute(property, &block)
      computations << Computation.new(self, property, &block)
    end

    def computations
      @computations ||= ComputationSet.new
    end

    def recompute_all!(*properties)
      self.all.each { |record| record.recompute!(*properties) }
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

  def recompute!(*properties)
    properties = properties.compact.flatten
    if properties.empty?
      self.class.computations.each_in_order { |c| c.apply(self) }
    else
      properties.each do |property|
        computation = self.class.computations.for_property(property)
        computation.apply(self)
      end
    end
    save
  end

  private

  def computed_fields_update_all
    computations_for_changed_properties(self.changed).each do |c|
      c.apply(self)
    end
  end

  def computations_for_changed_properties(changed_properties)
    self.class.computations.for_changed_properties(self.changed)
  end

end
