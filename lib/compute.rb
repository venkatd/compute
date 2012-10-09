require "compute/version"
require "compute/railtie" if defined? Rails

require 'compute/computation'
require 'compute/computation_graph'

require 'active_support/concern'

module Compute
  extend ActiveSupport::Concern

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

  included do
    around_save :execute_outdated_computations
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
    each_outdated_computation_for_changes(self.changed) { |computation| computation.execute(self) }
    yield
  end

  def each_outdated_computation_for_changes(changes)
    self.class.computations.for_changed_properties(changes).each { |c| yield c }
  end

end
