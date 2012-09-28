require "compute/version"
require "compute/railtie" if defined? Rails

require 'compute/computation'
require 'compute/computation_graph'

module Compute

  module ClassMethods

    def compute(property, &block)
      computations << Computation.new(self, property, &block)
    end

    def computations
      @computations ||= ComputationGraph.new
    end

    def recompute!(*properties)
      scoped.each { |record| record.recompute!(*properties) }
    end

  end

  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      around_save :execute_outdated_computations
    end
  end

  def recompute!(*properties)
    properties = properties.compact.flatten
    if properties.empty?
      self.class.computations.each_in_order { |c| c.execute(self) }
    else
      properties.each do |property|
        computation = self.class.computations.for_property(property)
        computation.execute(self)
      end
    end
    save
  end

  private

  def execute_outdated_computations
    yield

    each_outdated_computation { |computation| computation.execute(self) }
  end

  def each_outdated_computation
    self.class.computations.for_changed_properties(self.changed).each { |c| yield c }
  end

end
