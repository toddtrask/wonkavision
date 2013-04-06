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

        attr_reader :owner
        def initialize(owner)
          @owner = owner
        end

        #Aggregations persistence support
        #
        # Takes a Wonkavision::Analytics::Query and returns an array of
        # matching tuples
        def execute_query(query, &block)
          dimension_names = query.all_dimensions? ? [] :
            query.referenced_dimensions.dup.
              concat(Wonkavision::Analytics.context.global_filters.
              select{ |f| f.dimension?}.map{ |dim_filter| dim_filter.name.to_s }).uniq.
              sort{ |a,b| a.to_s <=> b.to_s }

          filters = (query.filters + Wonkavision::Analytics.context.global_filters).compact.uniq

          fetch_tuples(dimension_names, filters, &block)
        end

        def facts_for(aggregation,filters,options={})
          filters = (filters + Wonkavision::Analytics.context.global_filters).compact.uniq
          fetch_facts(aggregation,filters,options)
        end
       
        def where(query)
          raise NotImplementedError
        end

        def each(query, &block)
          raise NotImplementedError
        end

        protected

        #Abstract methods
        def fetch_facts(aggregation,filters,options)
          raise NotImplementedError
        end
      
        def fetch_tuples(dimension_names, filters = [])
          raise NotImplementedError
        end
      
      end
    end
  end
end
