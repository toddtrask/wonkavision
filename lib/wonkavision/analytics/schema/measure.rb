module Wonkavision
  module Analytics
    module Schema
      class Measure
        attr_reader :name, :options, :format, :cube, :calculation, :field_name

        def initialize(cube, name,options={},&block)
          @cube = cube
          @name = name
          @field_name = options[:field_name] || name
          @format = options.delete(:format)
          @options = options
          @calculation = nil
          if options[:calculation]
            @calculation = options[:calculation]
          end
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def calculated?
          !!@calculation
        end

        def calculate!(context)
          raise "#calculate! should only be called on a calculated measure" unless calculated?
          (calculation.arity == 1 ? calculation.call(context) : context.instance_eval(&calculation))
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

