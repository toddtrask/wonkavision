module Wonkavision
  module Api
    class Helper

      LIST_DELIMITER = "|"

      attr_reader :schema
      
      def initialize(schema)
        @schema = schema
      end

      def query_from_params(params)
        query = Wonkavision::Analytics::Query.new

        query.from(params["from"])
        #dimensions
        ["columns","rows","pages","chapters","sections"].each do |axis|
          if dimensions = parse_list(params[axis])
            query.select( *dimensions, :axis => axis )
          end
        end

        #measures
        query.measures parse_list params["measures"] if params["measures"]

        #filters
        filters = parse_filters(params["filters"])
        filters.each do |member_filter|
          query.add_filter member_filter
        end

        query.attributes(*parse_refs(params["attributes"]))
        query.order(*parse_refs(params["order"]))

        count,dimension,options = *parse_top_filter(params)
        if count > 0 && dimension
          query.top count, dimension, options
        end

        query
      end

      def dimension_query_from_params(params)
        query = Wonkavision::Analytics::DimensionQuery.new
        query.from  params["from"]
        #filters
        filters = parse_filters(params["filters"])
        filters.each do |member_filter|
          query.add_filter member_filter
        end

        query.attributes(*parse_refs(params["attributes"]))
        query.order(*parse_refs(params["order"]))

        query
      end


      def execute_query(params)
        query = query_from_params(params)
        schema.execute_query(query).serializable_hash
      end

      def execute_dimension_query(params)
        query = dimension_query_from_params(params)
        schema.execute_dimension_query(query)
      end

      def facts_for(params)
        query = query_from_params(params)
        options = params.slice(:page,:per_page,:sort)
        facts_data = schema.facts_for(query, options)
        response = {
          :cube => query.from,
          :data => facts_data
        }
        if facts_data.kind_of?(Wonkavision::Analytics::Paginated)
          response[:pagination] = facts_data.pagination_data
        end
        response
      end
     
      def parse_filters(filters_string)
        filters = parse_list(filters_string) || []
        filters.map{ |f| Wonkavision::Analytics::MemberFilter.parse(f) }
      end

      def parse_top_filter(params)
        count = params["top_filter_count"].to_i
        dimension = params["top_filter_dimension"]
        options = {}
        options[:by] = params["top_filter_measure"] if params["top_filter_measure"]
        options[:exclude] = parse_list(params["top_filter_exclude"])
        options[:filters] = parse_filters(params["top_filter_filters"])
        [count,dimension,options]
      end

      def parse_refs(refs_string)
        references = parse_list(refs_string) || []
        references.map{|a| Wonkavision::Analytics::MemberReference.parse(a)}
      end
        
      def parse_list(list_candidate)
        return nil if list_candidate.blank?
          list_candidate.kind_of?(Array) ? 
            list_candidate :
            list_candidate.to_s.split(LIST_DELIMITER).map{|item|item.strip}.compact
      end

    end
  end
end
