module Wonkavision
  module Analytics
    module Aggregation
      extend ActiveSupport::Concern

      def self.all
        @@all ||= {}
      end

      included do
        class_attribute :aggregation_options, :instance_write => false
        self.aggregation_options = {}

        class_attribute :aggregation_spec, :instance_writer => false
        self.aggregation_spec = AggregationSpec.new(name)
      
        Aggregation.all[name] = self
      end

      module ClassMethods
        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ?
              store.store_name : new_store
            
            
            store = store.new(self) if store.respond_to?(:new)

            aggregation_options[:store] = store
          else
            store_name = aggregation_options[:store] || :default
            klass = Wonkavision::Analytics::Persistence::Store[store_name]
            raise "Wonkavision could not find a store of type #{store_name}" unless klass
            @store ||= klass.new(self)
          end
        end


        def [](dimensions)
          key = [dimension_names(dimensions),dimension_keys(dimensions)]
          @instances ||= HashWithIndifferentAccess.new
          @instances[key] ||= self.new(dimensions)
        end

        def aggregates(facts_class = nil)
          return aggregation_options[:facts_class] unless facts_class

          facts_class.aggregations << self
          aggregation_options[:facts_class] = facts_class
        end
        alias facts aggregates

        def dimension_names(dimensions)
          dimensions.keys.sort
        end

        def dimension_keys(dimensions)
          dims = self.dimensions
            dimension_names(dimensions).map do |dim|
            dimensions[dim][dims[dim].key.to_s]
          end
        end

        def query(options={},&block)
          raise "Aggregation#query is not valid unless a store has been configured" unless store
          query = Wonkavision::Analytics::Query.new
          query.instance_eval(&block) if block
          query.validate!

          return query if options[:defer]

          execute_query(query)
        end

        def execute_query(query)
          tuples = store.execute_query(query)
          Wonkavision::Analytics::CellSet.new( self,
                                               query,
                                               tuples )
        end

        def facts_for(filters, options={})
          raise "Cannot provide underlying facts. Did you forget to associate your aggregation with a Facts class using 'aggregates' ? " unless aggregates

          aggregates.facts_for(self, filters, options)
        end


        def method_missing(m,*args,&block)
          aggregation_spec.respond_to?(m) ? aggregation_spec.send(m,*args,&block) : super
        end
      
      end

      attr_reader :dimensions, :measures

      def initialize(dimensions)
        @dimensions = dimensions
      end
     
      def dimension_names
        @dimension_names ||= self.class.dimension_names(@dimensions)
      end

      def dimension_keys
        @dimension_keys ||= self.class.dimension_keys(@dimensions)
      end

    end
  end
end
