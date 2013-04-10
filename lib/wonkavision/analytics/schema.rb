module Wonkavision
  module Analytics
    module Schema
      extend ActiveSupport::Concern

      included do
        class_attribute :schema_options, :instance_writer => false
        self.schema_options = {}

        class_attribute :dimensions, :instance_writer => false
        self.dimensions = HashWithIndifferentAccess.new

        class_attribute :cubes, :instance_write => false
        self.cubes = HashWithIndifferentAccess.new
      end

      module ClassMethods
        
        def dimension(name, options={}, &block)
          dimensions[name] = Dimension.new(self, name,options,&block)
        end

        def cube(name, options={}, &block)
          cubes[name] = Cube.new(self, name,options,&block)
        end

        def execute_query(query, options = {})
          query.validate!(self)
          tuples = store.execute_query(query)
          options[:raw] ? tuples : Wonkavision::Analytics::CellSet.new(self, query, tuples)
        end

        def facts_for(query, options = {})
          query.validate!(self)
          store.facts_for(query, options)
        end

        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ?
              store.store_name : new_store
            
            schema_options[:store] = store
          else
            store_name = schema_options[:store] || :default
            if store_name.to_s != "none"
              klass = Wonkavision::Analytics::Persistence::Store[store_name]
              raise "Wonkavision could not find a store of type #{store_name}" unless klass
              @store ||= klass.new(self)
            end
          end
        end

      end

    end
  end
end