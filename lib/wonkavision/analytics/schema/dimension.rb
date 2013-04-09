module Wonkavision
  module Analytics
    module Schema
      class Dimension
        attr_reader :name, :attributes, :options, :schema, :table_name, :source_dimension
        attr_writer :key, :sort, :caption

        def initialize(schema, name,options={},&block)
          @schema = schema
          @name = name
          @options = options
          @attributes = HashWithIndifferentAccess.new
          @table_name = options[:table_name] || "dim_#{name}"
          @source_dimension = self
          key options[:key] if options[:key]
          sort options[:sort] if options[:sort]
          caption options[:caption] if options[:caption]
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
          key "#{name}_key" unless @key
          caption "#{name}_name" unless @caption
        end

        def attribute(name = nil, options={}, &block)
          @attributes[name] = Attribute.new(self, name,options,&block)
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
          return @table_name unless table_name
          @table_name = table_name
        end


      end
    end
  end
end

