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
              @db = Class.new(ActiveRecord::Base) do
                def self.name
                  "ActiveRecordStoreTestHelper"
                end
              end
              @db.establish_connection(config_or_model)
            end
            @arel_engine = @db
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

        def execute_raw_query(query, options={})
          connection.execute(query.to_s)
        end

        def execute_dimension_query(query,options={})
          dimension = schema.dimensions[query.from]
          sql = create_sql_query(query, dimension, options)
          connection.execute(sql.to_sql)
        end

        def facts_for(query, options = {})
          cube = schema.cubes[query.from]
          sql = create_sql_query(query, cube, options.merge(:group => false))
          paginated =  paginate(sql, options)
          sql_string = sql.to_sql(self)
          data = connection.execute(sql_string)
          Paginated.apply(data, paginated) if paginated
          data
        end

        def create_sql_query(query,datasource,options)
          #query may be of type Query or DimensionQuery
          #datasource may be of type Cube or Dimension, depending on the type of query
          if query.kind_of?(DimensionQuery)
            DimensionQueryBuilder.new(self,query,datasource,options).execute()
          else
            QueryBuilder.new(self,query,datasource,options).execute()
          end
        end

        def paginate(sql, options)
          if options[:page] || options[:per_page]
            countsql = "select count(*) from (#{sql.to_sql(self)}) as cnt"
            rcount = connection.execute(countsql).first["count"].to_i
            page = options[:page] ? options[:page].to_i : 1
            per_page = options[:per_page] ? options[:per_page].to_i : 25
            sql.skip((page-1) * per_page)
            sql.take(per_page)
            {:current_page => page, :per_page=>per_page, :total_entries=>rcount}
          else
            false
          end
        end

      end
    end
  end
end
