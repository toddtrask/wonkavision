module Wonkavision
  module Analytics
    module Schema
      class CubeDimension
        attr_reader :name, :dimension, :options, :cube, :linked_cube_name, :linked_dimension_name

        def initialize(cube, name, options={},&block)
          @cube = cube
          @name = name
          @options = options
          @dimension = options[:as] ? as(options[:as]) : as(name)
          @foreign_key = options[:foreign_key] || "#{name}_key"
          @linked_cube_name = options[:through]
          @linked_cube = nil
          @linked_dimension_name = options[:via]
          @linked_dimension = nil

          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
        end

        def as(dimension_name=nil)
          return @dimension unless dimension_name
          @dimension = schema.dimensions[dimension_name]
        end

        def schema
          @cube.schema
        end

        def foreign_key(key = nil)
          return (linked_dimension ? linked_dimension.foreign_key : @foreign_key) unless key
          @foreign_key = key
        end

        def primary_key
          dimension.source_dimension.primary_key
        end

        def attribute_key(attribute_name)
          dimension.respond_to?(attribute_name) ? dimension.send(attribute_name.to_s) :
                                                  attribute_name
        end

        def source_cube
          has_linked_cube? ? linked_cube.linked_cube : cube
        end

        def linked_cube
          return nil unless @linked_cube_name
          unless @linked_cube ||= cube.linked_cubes[@linked_cube_name]
            raise "Cannot link through cube #{@linked_cube_name} because it does not exist"
          end
          @linked_cube
        end

        def linked_dimension
          return nil if @linked_dimension_name.blank?
          unless @linked_dimension ||= cube.dimensions[@linked_dimension_name]
            raise "Cannot link via dimension #{@linked_dimension_name} because it does not exist"
          end
          @linked_dimension
        end

        def via(linked_dim_name=nil)
          return @linked_dimension_name unless linked_dim_name
          @linked_dimension = nil
          @linked_dimension_name = linked_dim_name
        end

        def through(linked_cube_name = nil)
          return linked_cube unless linked_cube_name
          @linked_cube = nil
          @linked_cube_name = linked_cube_name
        end

        def has_linked_cube?
          !!@linked_cube_name
        end

        def has_linked_dimension?
          !!@linked_dimension_name
        end

      end
    end
  end
end

