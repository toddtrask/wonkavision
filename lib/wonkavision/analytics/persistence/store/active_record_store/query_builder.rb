module Wonkavision
  module Analytics
    module Persistence
      class ActiveRecordStore
        class QueryBuilder

          attr_reader :store, :query, :cube, :options, :sql, :group, :project, :root_table
          attr_reader :excluded_dimensions, :skip_top_filter

          def initialize(store,query,cube,options)
            @store = store
            @query = query
            @cube = cube
            @options = options
            @tables = {}
            @group_by = {}
            @order_by = {}
            @root_table = cube_table(cube) 
            @sql = root_table.from(root_table)
            @group = options[:group] == false ? false : true
            @project = options[:project] == false ? false : true
            @skip_top_filter = !!options[:skip_top_filter]
            @excluded_dimensions = [options[:excluded_dimensions]].flatten.uniq.compact.flatten.map(&:to_sym)
          end

          def execute()
            referenced_dims = query.referenced_dimensions.map{|d|cube.dimensions[d]}  
            selected_dims = query.selected_dimensions.map{|d|cube.dimensions[d]}

            linked_cubes = referenced_dims.select(&:has_linked_cube?).map{|d|d.linked_cube}.
                           concat(query.referenced_facts.map{|f|cube.linked_cubes[f]}).
                           uniq.compact


            #include all measures in the SQL so calcs will have
            #required source measures to work with. When serializing for
            #transport over the network only selected measures
            #will be included.
            selected_measures = cube.measures.values.reject{|m|m.calculated?}

            linked_cubes.each{|link|join_linked_cube(link)}
            
            query.order.each do |o|
              order_by_attribute(o)
            end

            selected_dims.each{|d|join_dimension(d)}
            selected_measures.each{|m| project_measure(m) } if project
            sql.project(Arel.sql('*').count.as('record_count__count')) if group && project
            
            query.filters.each do |f|
              apply_filter(f)
            end

            query.attributes.each do |a|
              project_attribute(a)
            end

            apply_top_filter

            sql
          end

          def linked_cube_table(link)
            cube = link.linked_cube
            join_on = link.join_on
            arel_table cube.table_name, :join_on => join_on
          end

          def cube_table(cube, pkey=nil, fkey=nil)
            arel_table cube.table_name, :pkey => pkey, :fkey => fkey
          end

          def dim_table(cube_dim)
            table_name = cube_dim.dimension.source_dimension.table_name
            pkey = cube_dim.primary_key
            fkey = cube_dim.foreign_key

            arel_table table_name, :pkey => pkey,
                                   :fkey => fkey,
                                   :table_alias => cube_dim.name,
                                   :cube => cube_dim.source_cube
          end

          def arel_table(table_name, opts = {})
            pkey = opts[:pkey]
            fkey = opts[:fkey]
            join_on = opts[:join_on]
            join_on = {fkey => pkey} if join_on.nil? && pkey && fkey
            table_alias = opts[:table_alias]
            source_cube = opts[:cube] || self.cube

            cache_key = [table_name, cube.name, join_on]
            
            @tables[cache_key] ||= begin
              jointarget = (source_cube == cube) ? root_table : cube_table(source_cube)
              sqltable = Arel::Table.new(table_name, store.class.arel_engine)
              sqltable = table_alias.blank? ? sqltable : sqltable.alias(table_alias)
              if join_on
                join_criteria = join_on.map do |fkey,pkey|
                  pkey_node = sqltable[pkey]
                  fkey_node = jointarget[fkey]
                  fkey_node.eq pkey_node
                end
                onclause = join_criteria.shift
                join_criteria.each{|c|onclause = onclause.and(c)}
                sql.join(sqltable).on(onclause)
              end
              sqltable
            end
          end
          
          def apply_filter(filter, bypassExclusions = false)
            return if filter.dimension? && excluded_dimensions.include?(filter.name.to_sym) && !bypassExclusions
            
            filter_attr = table_attr_from_reference(filter, cube)
            arel_op = filter_op_to_arel_op(filter.operator)
            sql.where(filter_attr.send(arel_op, filter.value))
          end

          def apply_top_filter
            return if skip_top_filter || query.top_filter.blank?
            top = query.top_filter
            cubedim = cube.dimensions[top[:dimension]]
            options = {
              :excluded_dimensions => [top[:exclude]].flatten,
              :project => false,
              :group => group,
              :skip_top_filter => true
            }
            subq = QueryBuilder.new(store,query,cube,options)
            top[:filters].each{|f|subq.apply_filter(f, true)}

            subsql = subq.execute.take(top[:count])
            #subsql.join_dimension(cubedim, false, false, true)

            order_by_expr = if cubem = cube.measures[top[:measure]]
              "#{cubem.default_aggregation}(#{cubem.name})"
            else
              "COUNT(*)"
            end

            subqdimtable = subq.dim_table(cubedim)
            dimtable = dim_table(cubedim)

            fkey_node = subqdimtable[cubedim.dimension.key]
            subsql.project(fkey_node).group(fkey_node)
            subsql.project("dense_rank() OVER(ORDER BY #{order_by_expr} DESC) as rank")
            subsql = Arel::Nodes::SqlLiteral.new("INNER JOIN(#{subsql.to_sql}) as topfilter on topfilter.#{cubedim.dimension.key} = #{dimtable.name}.#{cubedim.dimension.key}")
            sql.join(subsql)
            sql.project("topfilter.rank as #{cubedim.name}__rank")
            sql.group("topfilter.rank") if group
          end


          def project_attribute(attribute)
            member_attr = table_attr_from_reference(attribute, cube)
            member_attr = member_attr.as("#{attribute.name}__#{attribute.attribute_name}") if attribute.dimension?
            sql.project(member_attr)
          end

          def order_by_attribute(attribute)
             order_attr = table_attr_from_reference(attribute, cube).send(attribute.order)
             sql.order(order_attr)
          end

          def project_measure(measure)
            #record count is a special measure
            return if measure.name.to_s == "record_count" && measure.default_aggregation.to_s == "count"
            table = cube_table(measure.cube)
            mattr = table[measure.field_name]
            if group
              sql.project(
                mattr.count.as("#{measure.name}__count"),
                mattr.sum.as("#{measure.name}__sum"),
                mattr.minimum.as("#{measure.name}__min"),
                mattr.maximum.as("#{measure.name}__max")
              )
            else
              sql.project(mattr)
            end
          end

          def join_linked_cube(link)
            linked_cube_table(link)
          end

          def join_dimension(cube_dimension, project = @project, group = @group, bypassExclusions = false)
            return if excluded_dimensions.include?(cube_dimension.name) && !bypassExclusions

            cubetable = cube_table(cube_dimension.source_cube)
            dimtable = dim_table(cube_dimension)
            
            dimkey = dimtable[cube_dimension.dimension.key]
            caption = dimtable[cube_dimension.dimension.caption]
          
            sql.project(
              dimkey.as("#{cube_dimension.name}__key"),
              caption.as("#{cube_dimension.name}__caption")
            ) if project
            group_by(dimkey, caption) if group

            if (sort_key = cube_dimension.dimension.sort) && project
              sort = dimtable[sort_key]
              if group
                sql.project(sort.minimum.as("#{cube_dimension.name}__sort"))
              else
                sql.project(sort.as("#{cube_dimension.name}__sort"))
                sql.order(sort)
              end
            end
          end

          def group_by(*group_fields)
            group_fields.each do |g|
              @group_by[g] ||= begin
                sql.group(g)
                g
              end
            end
          end

          def table_attr_from_reference(member_ref, cube)
             member_attr = if member_ref.dimension?
              cubedim = cube.dimensions[member_ref.name]
              dimtable = dim_table(cubedim)
              attr_name = cubedim.attribute_key(member_ref.attribute_name)
              dimtable[attr_name]
            elsif member_ref.fact?
              cube_table(cube.schema.cubes[member_ref.name])[member_ref.attribute_name]
            else
              cube_table(cube)[member_ref.name]
            end
            member_attr
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