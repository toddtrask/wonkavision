module Wonkavision
  module Analytics
    module Schema
      class Measure
        attr_reader :name, :options, :format, :cube

        def initialize(cube, name,options={},&block)
          @cube = cube
          @name = name
          @format = options.delete(:format)
          @options = options
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def default_aggregation
          options[:default_aggregation] || :sum
        end

        def format(format=nil, format_options={})
          return @format unless format
          options.merge!(format_options)
          @format = format
          self
        end

        def schema
          cube.schema
        end

      end
    end
  end
end

