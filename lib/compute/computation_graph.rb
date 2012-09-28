require 'tsort'

module Compute

  class CyclicComputation < StandardError
  end

  class ComputationGraph < Hash
    include TSort

    def initialize
      @sorted_computations = []
      @computations_for_changed_properties = Hash.new do |h, changed_properties|
        @sorted_computations.select { |c| c.needs_update?(changed_properties) }
      end
    end

    def <<(computation)
      self[computation.property] = computation
      sort!
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

    private

    def sort!
      begin
        @sorted_computations = tsort.map { |p| self[p] }.compact
      rescue TSort::Cyclic => e
        raise CyclicComputation, "You have computations that depend on each other which would cause an infinite loop."
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

  end

end