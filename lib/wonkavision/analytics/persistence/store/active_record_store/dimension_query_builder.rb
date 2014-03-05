module Wonkavision
  module Analytics
    module Persistence
      class ActiveRecordStore
        class DimensionQueryBuilder

          attr_reader :store, :query, :dimension, :options, :sql, :root_table

          def initialize(store,query,dimension,options)
            @store = store
            @query = query
            @dimension = dimension
            @options = options
            @tables = {}
            @group_by = {}
            @order_by = {}
            @root_table = dimension_table(dimension) 
            @sql = root_table.from(root_table)
          end

          def execute()
            query.order.each do |o|
              order_by_attribute(o)
            end

            query.filters.each do |f|
              apply_filter(f)
            end

            if query.attributes.present?
              query.attributes.each do |a|
                project_attribute(a)
              end
            else
              sql.project(Arel.sql('*'))
            end
            sql
          end

          def dimension_table(dimension)
            table_name = dimension.table_name
            Arel::Table.new(table_name,store.class.arel_engine)
          end

          def apply_filter(filter)
            filter_attr = table_attr_from_reference(filter)
            arel_op = filter_op_to_arel_op(filter.operator)
            sql.where(filter_attr.send(arel_op, filter.value))
          end

          def project_attribute(attribute)
            member_attr = table_attr_from_reference(attribute)
            member_attr = member_attr.as("#{attribute.name}__#{attribute.attribute_name}") if attribute.dimension?
            sql.project(member_attr)
          end

          def order_by_attribute(attribute)
             order_attr = table_attr_from_reference(attribute).send(attribute.order)
             sql.order(order_attr)
          end

          def table_attr_from_reference(ref)
            attr_name = dimension.respond_to?(ref.attribute_name) ?
              dimension.send(ref.attribute_name.to_s) :
              ref.attribute_name
            root_table[attr_name]
          end

          def filter_op_to_arel_op(filter_op)
            case filter_op
            when :gte then :gteq
            when :lte then :lteq
            when :nin then :not_in
            when :ne then :not_eq
            else filter_op
            end
          end
        end
      end
    end
  end
end