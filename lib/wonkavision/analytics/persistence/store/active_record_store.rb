

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

        def execute_query(query)
          query.validate!
          cube = schema.cubes[query.from]
          raise "A cube named #{query.from} was not found in the schema #{schema.name}" unless cube
          
          sql = create_sql_query(query, cube)
          connection.execute(sql.to_sql)
        end

        private 

        def create_sql_query(query, cube)
          referenced_dims = query.referenced_dimensions.map{|d|cube.dimensions[d]}  
          selected_dims = query.selected_dimensions.map{|d|cube.dimensions[d]}
          slicer_dims = query.slicer_dimensions.map{|d|cube.dimensions[d]}

          selected_measures = query.selected_measures.map{|m|cube.measures[m]}

          cubetable = table(cube)
          sql = sql_query(cubetable)
          
          selected_dims.each{|d|join_dimension(d, cubetable, sql)}
          slicer_dims.each{|d|join_dimension(d, cubetable, sql, false)}
          selected_measures.each{|m| project_measure(m, cubetable, sql) }
          sql.project(Arel.sql('*').count.as('record_count'))
          
          query.filters.each do |f|
            apply_filter(f, cube, sql)
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
          filter_attr = if filter.dimension?
            cubedim = cube.dimensions[filter.name]
            dimtable = table(cubedim)
            attr_name = cubedim.attribute_key(filter.attribute_name)
            dimtable[attr_name]
          else
            filter_attr = table(cube)[filter.name]
          end
          arel_op = filter_op_to_arel_op(filter.operator)
          sql.where(filter_attr.send(arel_op, filter.value))
        end

        def project_measure(measure, table, sql)
          mattr = table[measure.name]
          sql.project(
            mattr.count.as("#{measure.name}_count"),
            mattr.sum.as("#{measure.name}_sum"),
            mattr.minimum.as("#{measure.name}_min"),
            mattr.maximum.as("#{measure.name}_max")
          )
        end

        def join_dimension(cube_dimension, cubetable, sql, project = true)
          dimtable = table(cube_dimension)
          pkey = dimtable[cube_dimension.dimension.source_dimension.key]
          fkey = cubetable[cube_dimension.foreign_key]
          dimkey = dimtable[cube_dimension.dimension.key]
          caption = dimtable[cube_dimension.dimension.caption]

          sql.join(dimtable).on(
            fkey.eq pkey
          )
          sql.project(
            dimkey.as("#{cube_dimension.name}_key"),
            #prefix(fkey, cube_dimension.name),
            caption.as("#{cube_dimension.name}_caption")
            #prefix(caption, cube_dimension.name)
          ).group(dimkey, caption) if project

          if sort_key = cube_dimension.dimension.sort
            sort = dimtable[sort_key].minimum
            sql.project(sort.as("#{cube_dimension.name}_sort")).order("#{cube_dimension.name}_sort")
          end
        end

        def prefix(name, prefix)
          attribute.as("#{prefix}_#{name}")
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