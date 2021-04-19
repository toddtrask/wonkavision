module Wonkavision
  module Analytics
    module Schema
      class Cube
        attr_reader :name, :measures, :options, :dimensions, :key, :schema, :table_name, :linked_cubes

        def initialize(schema, name,options={},&block)
          @schema = schema
          @name = name
          @options = options
          @dimensions = HashWithIndifferentAccess.new
          @measures = HashWithIndifferentAccess.new
          @linked_cubes = HashWithIndifferentAccess.new
          @key = "#{name}_key"
          @table_name = options[:table_name] || "fact_#{name}"
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
          count(:record_count, :format=>:integer) unless @measures[:record_count]
        end

        def dimension(name, options={}, &block)
          @dimensions[name] = CubeDimension.new(self, name, options, &block)
        end

        def measure(name, options={}, &block)
          @measures[name] = Measure.new(self, name, options, &block)
        end

        def sum(name, options={}, &block)
          measure name, options.merge(:default_aggregation=>:sum), &block
        end

        def average(name, options={}, &block)
          measure name, options.merge(:default_aggregation=>:average), &block
        end

        def count(name, options={}, &block)
          measure name, options.merge(:default_aggregation=>:count), &block
        end

        def min(name, options={}, &block)
          measure name, options.merge(:default_aggregation=>:min), &block
        end

        def max(name, options={}, &block)
          measure name, options.merge(:default_aggregation=>:max), &block
        end

        def calc(name, options={}, &calculation)
          measure name, options.merge(:default_aggregation=>:calc, :calculation=>calculation)
        end

        def key(key_field=nil)
          return @key unless key_field
          @key = key_field
          self
        end

        def measure_names
          @measures.keys
        end

        def table_name(table_name_input=nil)
          return @table_name unless table_name_input
          @table_name = table_name_input
        end

        def link_to(cube_name, options={}, &block)
          linked = LinkedCube.new(self, cube_name, options, &block)
          @linked_cubes[linked.name] = linked
        end

      end
    end
  end
end

