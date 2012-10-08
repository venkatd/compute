module Compute

  class Computation

    attr_accessor :property

    def initialize(model, property, &block)
      @model = model
      @property = property
      @proc = Proc.new(&block)
    end

    def dependencies
      @dependencies ||= calculate_dependencies(@proc)
    end

    def needs_update?(changed_properties)
      common_changes = changed_properties.map(&:to_sym) & @dependencies
      common_changes.count > 0
    end

    def execute(record)
      source_values = source_values(record)
      destination_result = record.instance_exec(*source_values, &@proc)
      record.send(@property.to_s + '=', destination_result)
    end

    private

    def calculate_dependencies(proc)
      proc.parameters.map { |arg| arg[1] }
    end

    def source_values(record)
      @dependencies.map { |property| record.send(property) }
    end

  end

end