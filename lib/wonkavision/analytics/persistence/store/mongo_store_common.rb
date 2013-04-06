module Wonkavision
  module Analytics
    module Persistence
	  	module MongoStoreCommon
	    	def initialize(facts)
	          super(facts)
	        end

	        def facts_collection_name
	          "wv.#{owner.name.gsub("::",".").underscore}.facts"
	        end

	        def facts_collection
	          database.collection(facts_collection_name)
	        end

	        def aggregations_collection_name
	          "wv.#{owner.name.gsub("::",".").underscore}.aggregations"
	        end

	        def aggregations_collection
	          database.collection(aggregations_collection_name)
	        end

	        def[](document_id)
	          collection.find({ :_id => document_id}).to_a.pop
	        end

	        def where(criteria)
	          collection.find(criteria).to_a
	        end

	        def each(criteria, &block)
	        	collection.find(criteria).each(&block)
	        end

	        def count(criteria={})
	          collection.find(criteria).count
	        end

	        def collection
	          owner <=> Wonkavision::Analytics::Aggregation ? aggregations_collection :
	            facts_collection
	        end
       
	        protected

	        def find(criteria, options={})
	          collection.find(criteria,options).to_a
	        end

	        def find_and_modify(opts)
	          collection.find_and_modify(opts)
	        end

	        def fetch_facts(aggregation,filters,options={})
	          criteria = {}
	          append_facts_filters(aggregation,criteria,filters)
	         
	          find(criteria,options)
	        end
	      	        
	        #Aggregation persistence
	        def fetch_tuples(dimension_names, filters, &block)
	          criteria = dimension_names.blank? ? {} : { :dimension_names => dimension_names }
	          append_aggregations_filters(criteria,filters)
	          block ? each(criteria, &block) : find(criteria)
	        end

	        def remove_mongo_id(*documents)
	          unless owner.respond_to?(:record_id) && owner.record_id.to_s == "_id"
	            documents.compact.each { |doc| doc.delete("_id") }
	          end
	          documents.length > 1 ? documents : documents.pop
	        end

	        private
	        def append_aggregations_filters(criteria,filters)
	          filter_hash = merge_filters(filters,true) do |filter|
	            "#{filter.member_type}s.#{filter.name}.#{filter.attribute_key(owner)}"
	          end
	          criteria.merge! filter_hash
	        end

	        def append_facts_filters(aggregation,criteria,filters)
	          filter_hash = merge_filters(filters,false) do |filter|
	            filter_name = filter.dimension? ? filter.attribute_key(aggregation) : filter.name
	            prefix =      filter_prefix_for(aggregation,filter)

	            [prefix,filter_name].compact.join(".")
	          end
	          criteria.merge! filter_hash
	        end

	        def filter_value_for(criteria_hash)
	          return criteria_hash[:eq].value if criteria_hash[:eq]
	          filter_value = {}
	          criteria_hash.each_pair do |operator,filter|
	            filter_value["$#{operator}"] = filter.value
	          end
	          filter_value
	        end

	        def filter_prefix_for(aggregation,filter)
	          if filter.dimension?
	            dimension = aggregation.find_dimension(filter.name)
	            dimension.complex? ? dimension.from : nil
	          end
	        end

	        def transform_filter_hash(filter_hash)
	          transformed = {}
	          filter_hash.each_pair do |filter_key, filter_criteria|
	            transformed[filter_key] = filter_value_for(filter_criteria)
	          end
	          transformed
	        end

	        def merge_filters(filters,apply)
	          merged = {}
	          filters.each do |filter|
	            filter_key = yield(filter)
	            mf = merged[filter_key] ||= {}
	            if mf.empty?
	              mf[filter.operator] = filter
	            elsif mf[:eq]
	              assert_compatible_filters(mf[:eq], filter)
	            elsif filter.operator == :eq
	              #eq must be the only element in the filter.
	              #Therefore, if the current filter gets along with previous filters,
	              #we'll set it as the sole component to this criteria, otherwise,
	              #an error needs to be raised
	              mf.values.each{ |existing| assert_compatible_filters(filter,existing) }
	              mf.replace(:eq => filter)
	            elsif mf[filter.operator]
	              assert_compatible_filters(mf[filter.operator], filter)
	            else
	              mf[filter.operator] = filter
	            end
	            filter.applied! if apply
	          end
	          transform_filter_hash merged
	        end

	        def assert_compatible_filters(filter1,filter2)
	          ok = (filter1.operator == filter2.operator &&
	                filter1.value == filter2.value) || filter2.matches_value(filter1.value)
	          raise "Incompatible filters used: #{filter1.inspect} and #{filter2.inspect}" unless ok
	        end
	    end
    	end
    end
end
