module Wonkavision
  module Analytics
    module Schema
      class Dimension
        attr_reader :name, :attributes, :options, :schema
        attr_writer :key, :sort, :caption

        def initialize(schema, name,options={},&block)
          @schema = schema
          @name = name
          @options = options
          @attributes = HashWithIndifferentAccess.new
          key options[:key] if options[:key]
          sort options[:sort] if options[:sort]
          caption options[:caption] if options[:caption]
          if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
          end
          key "#{name}_key" unless @key
          caption "#{name}_name" unless @caption
        end

        def attribute(name, options={}, &block)
          @attributes[name] = Attribute.new(self, name,options,&block)
        end

        def sort(sort_key = nil, options={})
          return @sort || @key unless sort_key
          @sort = attribute(sort_key, options) unless attributes[sort_key]
        end

        def caption(caption_key=nil, options={})
          return @caption || @key unless caption_key
          @caption = attribute(caption_key, options) unless attributes[caption_key]
        end

        def key(key=nil, options={})
          return @key unless key
          @key = attribute(key, options) unless attributes[key]
        end

      end
    end
  end
end

