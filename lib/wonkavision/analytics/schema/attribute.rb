module Wonkavision
  module Analytics
    module Schema
      class Attribute
        attr_reader :name, :options, :dimension

        def initialize(dimension, name,options={})
          @dimension = dimension
          @name = name
          @options = options
        end

        def to_s
          @name.to_s
        end

      end
    end
  end
end

