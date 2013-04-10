module Wonkavision
  module Analytics
    module Persistence
      class Store

        def self.[](store_name)
          @stores ||= {}
          if store_name.to_s == "default"
            @stores["default"] ||= Wonkavision::Analytics.default_store          
          else
            @stores[store_name.to_s]
          end
        end

        def self.[]=(store_name,store)
          @stores ||= {}
          @stores[store_name.to_s] = store
        end

        def self.inherited(store)
          self[store.store_name] = store
        end

        def self.store_name
          name.split("::").pop.underscore
        end

        attr_reader :schema
        def initialize(schema)
          @schema = schema
        end

       
        # Takes a Wonkavision::Analytics::Query and returns an array of
        # matching tuples
        def execute_query(query)
          raise NotImplementedError
        end

        def facts_for(query,options={})
          raise NotImplementedError
        end
       
        def where(query)
          raise NotImplementedError
        end

        def each(query, &block)
          raise NotImplementedError
        end
      
      end
    end
  end
end
