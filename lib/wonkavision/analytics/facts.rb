require "set"

module Wonkavision
  module Analytics
    module Facts
      extend ActiveSupport::Concern

      included do
        class_attribute :facts_options, :instance_writer => false
        self.facts_options = {}

        class_attribute :aggregations, :instance_writer => false
        self.aggregations = []
       
      end

      module ClassMethods
     
        def record_id(new_record_id=nil)
          if new_record_id
            facts_options[:record_id] = new_record_id
          else
            facts_options[:record_id] ||= "id"
          end
        end

      
        def store(new_store=nil)
          if new_store
            store = new_store.kind_of?(Wonkavision::Analytics::Persistence::Store) ?
              store.store_name : new_store
            
            facts_options[:store] = store
          else
            store_name = facts_options[:store] || :default
            if store_name.to_s != "none"
              klass = Wonkavision::Analytics::Persistence::Store[store_name]
              raise "Wonkavision could not find a store of type #{store_name}" unless klass
              @store ||= klass.new(self)
            end
          end
        end

     
        def facts_for(aggregation,filters,options={})
          raise "Please configure a storage for your Facts class before attempting to use #facts_for" unless store
          store.facts_for(aggregation,filters,options)
        end
    
      end

      def store
        self.class.store
      end
      
    end
  end
end
