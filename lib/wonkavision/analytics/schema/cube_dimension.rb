module Wonkavision
  module Analytics
    module Schema
      class CubeDimension
        attr_reader :name, :dimension, :options, :cube

        def initialize(cube, name, options={},&block)
          @cube = cube
          @name = name
          @options = options
          @dimension = options[:as] ? as(options[:as]) : as(name)
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def foreign_key
          "#{name}_key"
        end

        def as(dimension_name=nil)
          return @dimension unless dimension_name
          @dimension = cube.schema.dimensions[dimension_name]
        end
      end
    end
  end
end

