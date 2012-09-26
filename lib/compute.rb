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

  class ComputationSet < Hash
    include TSort

    @sorted_computations = []
    @priorities = {}
    @triggers = {}

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

    def sort!
      @sorted_computations = tsort.map { |p| self[p] }.compact

      @triggers = Hash.new []
      each do |property, computation|
        computation.dependencies.each do |dependency|
          @triggers[dependency] << computation
        end
      end
      @triggers.each do |property, computations|
        sorted = @sorted_computations.select { |c| computations.include?(c) }
        computations.replace(sorted)
      end
    end

    def computations_for(property)
      if @triggers.include?(property)
        @triggers[property]
      else
        []
      end
    end

    def each_in_order
      @sorted_computations.each { |c| yield c }
    end

  end

  module ClassMethods

    def compute(property, &block)
      computation = Computation.new(self, property, &block)
      computations[computation.property] = computation

      computations.sort!
    end

    def computations
      @computations ||= ComputationSet.new
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
    self.class.computations.each_in_order do |computation|
      if computation.needs_update?(self)
        computation.update(self)
      end
    end
  end

end
