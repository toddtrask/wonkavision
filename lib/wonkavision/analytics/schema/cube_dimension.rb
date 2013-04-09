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
          @foreign_key = options[:foreign_key] || "#{name}_key"
          @link_dimension = options[:via] ? cube.dimensions[options[:via]] : self
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def as(dimension_name=nil)
          return @dimension unless dimension_name
          @dimension = cube.schema.dimensions[dimension_name]
        end

        def schema
          cube.schema
        end

        def foreign_key(key = nil)
          unless key
            @link_dimension == self ? @foreign_key : @link_dimension.foreign_key
          else
            @foreign_key = key
          end
        end

        def attribute_key(attribute_name)
          dimension.respond_to?(attribute_name) ? dimension.send(attribute_name.to_s) :
                                                  attribute_name
        end

        def via(link_dim_name=nil)
          return @link_dimension unless link_dim_name
          unless @link_dimension = cube.dimensions[link_dim_name]
            raise "Cannot link via #{link_dim_name} because it does not exist"
          end
          @link_dimension
        end

      end
    end
  end
end

