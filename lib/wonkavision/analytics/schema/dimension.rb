module Wonkavision
  module Analytics
    module Schema
      class Dimension
        attr_reader :name, :attributes, :options, :schema, :table_name, :source_dimension
        attr_reader :primary_key
        attr_writer :key, :sort, :caption

        def initialize(schema, name,options={},&block)
          @schema = schema
          @name = name
          @options = options
          @attributes = HashWithIndifferentAccess.new
          @table_name = options[:table_name] || "dim_#{name}"
          @primary_key = options[:primary_key] || "#{name}_key"
          @source_dimension = self
          @key = nil
          @caption = nil
          @sort = nil
          key options[:key] if options[:key]
          sort options[:sort] if options[:sort]
          caption options[:caption] if options[:caption]
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
          key @primary_key unless @key
          caption "#{name}_name" unless @caption
        end

        def attribute(name = nil, options={}, &block)
          @attributes[name] ||= Attribute.new(self, name,options,&block)
        end

        def sort(sort_key = nil, options={})
          return @sort unless sort_key
          @sort = attribute(sort_key, options)
        end

        def caption(caption_key=nil, options={})
          return @caption unless caption_key
          @caption = attribute(caption_key, options)
        end

        def key(key=nil, options={})
          return @key unless key
          @key = attribute(key, options)
        end

        def derived_from(source_dimension_name=nil)
          return @source_dimension unless source_dimension_name
          unless @source_dimension = schema.dimensions[source_dimension_name]
            raise "Cannot derive from #{source_dimension_name} because it does not exist"
          end
          @source_dimension
        end

        def table_name(table_name = nil)
          if table_name
            @table_name = table_name
          elsif has_calculated_attributes?
            #this dimension will be represented by a CTE in the query
            #which will be aliased with the dimensions name
            @name.to_s
          else
            source_table_name
          end
        end

        def source_table_name
          is_derived? ? source_dimension.table_name : @table_name
        end

        def primary_key(primary_key = nil)
          return @primary_key unless primary_key
          @primary_key = primary_key
        end

        def calculate(name, expression, options={})
          options = options.merge(:expression=>expression)
          attribute(name,options)
        end

        def calculated_attributes
          @attributes.values.select{|a|a.calculated?}
        end

        def has_calculated_attributes?
          calculated_attributes.present?
        end

        def is_derived?
          source_dimension != self
        end

      end
    end
  end
end

