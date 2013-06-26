require "test_helper"

class ActiveRecordStoreTest < ActiveSupport::TestCase
  ActiveRecordStore = Wonkavision::Analytics::Persistence::ActiveRecordStore

  context "ActiveRecordStore" do
    setup do
      @store = ActiveRecordStore.new(RevenueAnalytics)
    end

    # should "provide access to the underlying facts specification" do
    #   assert_equal @facts, @store.owner
    # end

    context "querying" do
      setup do
      end
      context "#create_sql_query" do
        setup do
          @query = Wonkavision::Analytics::Query.new
          @query.from(:transport)
          @query.columns :account_age_from_dos
          @query.rows :primary_payer_type, :primary_payer
          @query.measures :record_count, :current_balance
          @query.where :division => 1, :provider.caption => 'REACH', :measures.current_balance.gt => 0
          Wonkavision::Analytics.context.global_filters << Wonkavision::Analytics::MemberFilter.parse("dimension::division::another_attribute::in::[1,2]")
          @query.validate!(RevenueAnalytics)
        end
        teardown do
          Wonkavision::Analytics.context.global_filters.clear
        end
        context "for aggregate data" do
          setup do
            @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {})
            #arel 4 has a projections property, but 3.0 doesn't
            @projections = @sql.instance_eval('@ctx').projections
            #arel 4 has a criteria property, but 3.0 doesn't
            @wheres = @sql.instance_eval('@ctx').wheres
            @groups = @sql.instance_eval('@ctx').groups
          end
          should "select from the fact table" do
            assert_equal "fact_transport", @sql.froms[0].name
          end
          context "projections" do
            should "project selected dimension keys and names" do
              selected_keys = @projections.select{|n|n.is_a?(Arel::Nodes::As)}
              assert_equal 6, selected_keys.length
              assert selected_keys.detect{|n|n.right == "account_age_from_dos__key"}, "no age key"
              assert selected_keys.detect{|n|n.right == "account_age_from_dos__caption"}, "no age name"  
              assert selected_keys.detect{|n|n.right == "primary_payer_type__key"}, "no payer type key" 
              assert selected_keys.detect{|n|n.right == "primary_payer_type__caption"}, "no payer type name"  
              assert selected_keys.detect{|n|n.right == "primary_payer__key"}, "no payer key" 
              assert selected_keys.detect{|n|n.right == "primary_payer__caption"}, "no payer name"          
            end
            should "project measures" do
              selected_measures = @projections.select{|n|!n.is_a?(Arel::Nodes::As)}
              assert selected_measures.detect{|m|m.is_a?(Arel::Nodes::Sum) && m.expressions[0].name.to_s == "current_balance" && m.alias == "current_balance__sum"}, "sum"
              assert selected_measures.detect{|m|m.is_a?(Arel::Nodes::Count) && m.expressions[0].name.to_s == "current_balance" && m.alias == "current_balance__count"}, "count"
              assert selected_measures.detect{|m|m.is_a?(Arel::Nodes::Min) && m.expressions[0].name.to_s == "current_balance" && m.alias == "current_balance__min"}, "min"
              assert selected_measures.detect{|m|m.is_a?(Arel::Nodes::Max) && m.expressions[0].name.to_s == "current_balance" && m.alias == "current_balance__max"}, "max"
            end
            should "not project the included record_count" do
              selected_measures = @projections.select{|n|!n.is_a?(Arel::Nodes::As)}
              assert !selected_measures.detect{|m|m.is_a?(Arel::Nodes::Sum) && m.expressions[0].name.to_s == "record_count" && m.alias == "record_count__sum"},"record_count should not be present" 
            end
            should "project sorts" do
              selected_sorts = @projections.select{|n|n.is_a?(Arel::Nodes::Min) && n.alias =~ /.*_sort/ }
              assert selected_sorts.detect{|s|s.alias == "primary_payer__sort"}, "primary_payer"
              assert selected_sorts.detect{|s|s.alias == "account_age_from_dos__sort"}, "account age"
            end
          end
          should "join selected dimensions" do
            assert @sql.join_sources.detect{|join|join.left.left.name.to_s == "dim_aging_category" && join.left.right.to_s == "account_age_from_dos"}, "account age"
            assert @sql.join_sources.detect{|join|join.left.left.name.to_s == "dim_payer" && join.left.right.to_s == "primary_payer_type"}, "primary_payer_type"
            #joins are not duplicated - since payer uses the same dimension table and keys as payer_type, a new join is not needed
            #this is not just optimization, it changes the results if the joined table has more than one record per fact table key
            #assert @sql.join_sources.detect{|join|join.left.left.name.to_s == "dim_payer" && join.left.right.to_s == "primary_payer"}, "primary_payer"
          end
          should "join slicer dimensions" do
            assert @sql.join_sources.detect{|join|join.left.left.name.to_s == "dim_division" && join.left.right.to_s == "division"}, "division"
            assert @sql.join_sources.detect{|join|join.left.left.name.to_s == "dim_provider" && join.left.right.to_s == "provider"}, "provider"
          end
          should "join a source only once" do
            assert @sql.join_sources.select{|join|join.left.left.name.to_s == "dim_division" && join.left.right.to_s == "division"}.length == 1, "multiple identical joins"
          end
          should "filter dimensions" do
            assert @wheres.detect{|w|w.is_a?(Arel::Nodes::Equality) && w.left.name.to_s == "division_key" && w.right == 1}, "division_key=>1"
            assert @wheres.detect{|w|w.is_a?(Arel::Nodes::Equality) && w.left.name.to_s == "provider_name" && w.right == 'REACH'}, "provider_name=>reach"
            assert @wheres.detect{|w|w.is_a?(Arel::Nodes::GreaterThan) && w.left.name.to_s == "current_balance" && w.right == 0},"current_balance=>0"
          end
          should "group by projected dimension attributes" do
            assert_equal @projections.select{|n|n.is_a?(Arel::Nodes::As)}.length, @groups.length
          end
        end
        context "for detail data" do
          setup do
            @query.attributes :facts.transport.account_call_number, :dimensions.provider.rpm_source_key, :dimensions.current_payer.payer_name
            @query.order :facts.transport.current_balance.desc, :facts.transport.date_of_service_key
            @query.validate!(RevenueAnalytics)
            @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {:group=>false})
            @projections = @sql.instance_eval('@ctx').projections
            @groups = @sql.instance_eval('@ctx').groups
          end
          should "not group" do
            assert_equal 0, @groups.length
          end
        end
        context "facts related queries" do
          setup do
            @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {:group=>false})
            @store.connection.expects(:execute).returns([{"count"=>100}])
            @paginate = @store.send(:paginate, @sql, {:page=>2, :per_page=>50})
          end
          should "return true if paginated" do
            assert_equal( {:current_page=>2, :per_page=>50, :total_entries=>100}, @paginate )
          end
          should "apply the correct offset" do
            assert_equal 50, @sql.offset
          end
          should "apply the correct limit" do
            assert_equal 50, @sql.taken
          end
        end
        context "facts_for" do
          should "execute the query and set pagination" do
            @query.attributes :facts.transport.accountt_call_number, :dimensions.provider.rpm_source_key, :dimensions.current_payer.payer_name
            @query.order :facts.transport.current_balance.desc, :facts.transport.date_of_service_key
            @query.validate!(RevenueAnalytics)
            @store.connection.expects(:execute).returns([1,2,3])
            @store.connection.expects(:execute).returns([{"count"=>100}])
            result = @store.facts_for(@query, :page=>2, :per_page=>5)
            assert_equal [1,2,3], result
            assert_equal 100, result.total_entries
          end
        end            
      end
      context "linked cubes" do
        setup do
          @query = Wonkavision::Analytics::Query.new
          @query.from(:denial)
          @query.columns :payer, :division, :provider
          @query.measures :denial_balance
          @query.where :division => 1, :provider.caption => 'REACH', :measures.denial_balance.gt => 0, :facts.transport.current_balance.gt => 0
          @query.validate!(RevenueAnalytics)
        end
        should "not break" do
          @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {})
          expected = "SELECT \"payer\".\"payer_source_key\" AS payer__key, \"payer\".\"payer_name\" AS payer__caption, MIN(\"payer\".\"payer_name\") AS payer__sort, \"division\".\"division_key\" AS division__key, \"division\".\"division_name\" AS division__caption, \"provider\".\"provider_key\" AS provider__key, \"provider\".\"provider_name\" AS provider__caption, COUNT(\"fact_denial\".\"denial_balance\") AS denial_balance__count, SUM(\"fact_denial\".\"denial_balance\") AS denial_balance__sum, MIN(\"fact_denial\".\"denial_balance\") AS denial_balance__min, MAX(\"fact_denial\".\"denial_balance\") AS denial_balance__max, COUNT(*) AS record_count__count FROM \"fact_denial\" INNER JOIN \"fact_transport\" ON \"fact_denial\".\"account_key\" = \"fact_transport\".\"account_key\" INNER JOIN \"dim_payer\" \"payer\" ON \"fact_denial\".\"payer_key\" = \"payer\".\"payer_key\" INNER JOIN \"dim_division\" \"division\" ON \"fact_transport\".\"division_key\" = \"division\".\"division_key\" INNER JOIN \"dim_provider\" \"provider\" ON \"fact_transport\".\"provider_key\" = \"provider\".\"provider_key\" WHERE \"division\".\"division_key\" = 1 AND \"provider\".\"provider_name\" = 'REACH' AND \"fact_denial\".\"denial_balance\" > 0 AND \"fact_transport\".\"current_balance\" > 0 GROUP BY \"payer\".\"payer_source_key\", \"payer\".\"payer_name\", \"division\".\"division_key\", \"division\".\"division_name\", \"provider\".\"provider_key\", \"provider\".\"provider_name\""
          assert_equal expected, @sql.to_sql
        end
      end
      context "linked cubes with multi-column joins" do
        setup do
          @query = Wonkavision::Analytics::Query.new
          @query.from(:account_state)
          @query.columns :division, :provider
          @query.where :division => 1, :facts.transport.current_balance.gt => 0
          @query.validate!(RevenueAnalytics)
        end
        should "not break" do
          @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {})
          expected = "SELECT \"division\".\"division_key\" AS division__key, \"division\".\"division_name\" AS division__caption, \"provider\".\"provider_key\" AS provider__key, \"provider\".\"provider_name\" AS provider__caption, COUNT(*) AS record_count__count FROM \"fact_account_state\" INNER JOIN \"fact_transport\" ON \"fact_account_state\".\"provider_key\" = \"fact_transport\".\"provider_key\" AND \"fact_account_state\".\"account_call_number\" = \"fact_transport\".\"account_call_number\" INNER JOIN \"dim_division\" \"division\" ON \"fact_transport\".\"division_key\" = \"division\".\"division_key\" INNER JOIN \"dim_provider\" \"provider\" ON \"fact_account_state\".\"provider_key\" = \"provider\".\"provider_key\" WHERE \"division\".\"division_key\" = 1 AND \"fact_transport\".\"current_balance\" > 0 GROUP BY \"division\".\"division_key\", \"division\".\"division_name\", \"provider\".\"provider_key\", \"provider\".\"provider_name\""
          assert_equal expected, @sql.to_sql
        end
      end
      context "top_count" do
        setup do
          @query = Wonkavision::Analytics::Query.new
          @query.from(:transport)
          @query.columns :primary_payer, :primary_payer_type
          @query.rows :division
          @query.where :division => 1, :primary_payer => 2
          @query.top 5, :primary_payer, :exclude=>:division, :by => :current_balance, :where => {
            :provider=>3
          } 
        end
        should "not break" do
          #yeah I know shitty testing. This stuff is hard to test though :( Verified SQL by hand. Doesn't help
          #during future refactorings though.
          @sql = @store.send(:create_sql_query, @query, @store.schema.cubes[@query.from], {})
          #puts @sql.to_sql
        end
      end

    end
  end
end
