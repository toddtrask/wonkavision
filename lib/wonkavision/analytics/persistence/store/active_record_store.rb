

module Wonkavision
  module Analytics
    module Persistence
      class ActiveRecordStore < Store

        class << self

          attr_reader :db, :arel_engine

          def connect(config_or_model)
            if config_or_model.kind_of?(Class) &&
              config_or_model < ActiveRecord::Base
              @db = config_or_model
            else
              @db = Class.new(ActiveRecord::Base)
              @db.establish_connection(config_or_model)
            end
            @arel_engine = Arel::Sql::Engine.new(@db)
          end

          def connection
            @db.connection
          end

        end#end class methods

        def initialize(schema)
          super
          @tables = {}
        end

        def connection
          self.class.connection
        end

        def execute_query(query, options={})
          cube = schema.cubes[query.from]
          sql = create_sql_query(query, cube, options)
          connection.execute(sql.to_sql)
        end

        def facts_for(query, options = {})
          cube = schema.cubes[query.from]
          sql = create_sql_query(query, cube, options.merge(:group => false))
          if paginate(sql, options)
            #TODO - set total pages somehow
          end
          connection.execute(sql.to_sql)
        end

        private 

        def create_sql_query(query, cube, options)
          group = options.keys.include?(:group) ? options[:group] : true

          referenced_dims = query.referenced_dimensions.map{|d|cube.dimensions[d]}  
          selected_dims = query.selected_dimensions.map{|d|cube.dimensions[d]}
          slicer_dims = query.slicer_dimensions.map{|d|cube.dimensions[d]}

          selected_measures = query.selected_measures.map{|m|cube.measures[m]}

          cubetable = table(cube)
          sql = sql_query(cubetable)
          
          selected_dims.each{|d|join_dimension(d, cubetable, sql, true, group)}
          slicer_dims.each{|d|join_dimension(d, cubetable, sql, false, false)}
          selected_measures.each{|m| project_measure(m, cubetable, sql, group) }
          sql.project(Arel.sql('*').count.as('record__count')) if group
          
          query.filters.each do |f|
            apply_filter(f, cube, sql)
          end

          query.attributes.each do |a|
            project_attribute(a, cube, sql)
          end

          query.order.each do |o|
            order_by_attribute(o, cube, sql)
          end

          sql
        end

        def table(entity)
          unless @tables[entity]
            @tables[entity] = case entity
              when Wonkavision::Analytics::Schema::Cube then Arel::Table.new(entity.table_name, self.class.arel_engine)
              when Wonkavision::Analytics::Schema::Dimension then Arel::Table.new(entity.source_dimension.table_name, self.class.arel_engine)
              when Wonkavision::Analytics::Schema::CubeDimension then table(entity.dimension).alias(entity.name)
              else raise "I don't know how to infer a table from #{entity}"
            end
          end
          @tables[entity]
        end

        def sql_query(table)
          table.from(table)
        end
        
        def apply_filter(filter, cube, sql)
          filter_attr = table_attr_from_reference(filter, cube)
          arel_op = filter_op_to_arel_op(filter.operator)
          sql.where(filter_attr.send(arel_op, filter.value))
        end

        def project_attribute(attribute, cube, sql)
          member_attr = table_attr_from_reference(attribute, cube)
          member_attr = member_attr.as("#{attribute.name}__#{attribute.attribute_name}") if attribute.dimension?
          sql.project(member_attr)
        end

        def order_by_attribute(attribute, cube, sql)
           order_attr = table_attr_from_reference(attribute, cube).send(attribute.order)
           sql.order(order_attr)
        end

        def project_measure(measure, table, sql, group)
          mattr = table[measure.name]
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

        def join_dimension(cube_dimension, cubetable, sql, project, group)
          dimtable = table(cube_dimension)
          pkey = dimtable[cube_dimension.dimension.source_dimension.key]
          fkey = cubetable[cube_dimension.foreign_key]
          dimkey = dimtable[cube_dimension.dimension.key]
          caption = dimtable[cube_dimension.dimension.caption]

          sql.join(dimtable).on(
            fkey.eq pkey
          )
          sql.project(
            dimkey.as("#{cube_dimension.name}__key"),
            #prefix(fkey, cube_dimension.name),
            caption.as("#{cube_dimension.name}__caption")
            #prefix(caption, cube_dimension.name)
          ) if project
          sql.group(dimkey, caption) if group

          if sort_key = cube_dimension.dimension.sort
            sort = dimtable[sort_key]
            sql.project(sort.minimum.as("#{cube_dimension.name}__sort")) if group
          end if project
        end

        def paginate(sql, options)
          if options[:page] || options[:per_page]
            page = options[:page] ? options[:page].to_i : 1
            per_page = options[:per_page] ? options[:per_page].to_i : 25
            sql.skip(page * per_page)
            sql.take(per_page)
            true
          else
            false
          end
        end

        def table_attr_from_reference(member_ref, cube)
           member_attr = if member_ref.dimension?
            cubedim = cube.dimensions[member_ref.name]
            dimtable = table(cubedim)
            attr_name = cubedim.attribute_key(member_ref.attribute_name)
            dimtable[attr_name]
          else
            member_attr = table(cube)[member_ref.name]
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