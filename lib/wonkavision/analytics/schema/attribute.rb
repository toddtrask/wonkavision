module Wonkavision
  module Analytics
    module Schema
      class Attribute
        attr_reader :name, :options, :dimension, :expression

        def initialize(dimension, name,options={})
          @dimension = dimension
          @name = name
          @expression = options[:expression]
          @options = options
        end

        def to_s
          @name.to_s
        end

        def schema
          dimension.schema
        end

        def calculated?
          !!expression
        end

      end
    end
  end
end

