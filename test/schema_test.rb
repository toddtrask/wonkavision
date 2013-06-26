require "test_helper"
require File.join $test_dir, "test_schema.rb"

class SchemaTest < ActiveSupport::TestCase
  context "Schema" do
    setup do
      
    end

    should "maintain a list of defined dimensions" do
      assert RevenueAnalytics.dimensions.length >= 1
      assert RevenueAnalytics.dimensions.values[0].is_a?(Wonkavision::Analytics::Schema::Dimension)
    end

    should "maintain a list of defined cubes" do
      assert_equal 3, RevenueAnalytics.cubes.length
      assert RevenueAnalytics.cubes.values[0].is_a?(Wonkavision::Analytics::Schema::Cube)
    end

    should "set the specified storage" do
      assert RevenueAnalytics.store.kind_of?(Wonkavision::Analytics::Persistence::ActiveRecordStore)
      assert_equal RevenueAnalytics, RevenueAnalytics.store.schema
    end

    context "execute_query" do
      setup do
        test_data = File.join $test_dir, "queryresults.tuples"
        @test_data = eval(File.read(test_data))
        @query = Wonkavision::Analytics::Query.new
        @query.from(:transport)
        @query.columns :account_age_from_dos
        @query.rows :primary_payer_type, :primary_payer
        @query.measures :current_balance
        @query.where :division => 1, :provider.caption => 'REACH', :measures.current_balance.gt => 0

        RevenueAnalytics.store.expects(:execute_query).with(@query).returns(@test_data)
      end
      should "execute the query and return a cellset" do
        result = RevenueAnalytics.execute_query(@query)
        assert result.is_a?(Wonkavision::Analytics::CellSet)
      end
      should "return raw data when raw is requested" do
        result = RevenueAnalytics.execute_query(@query, :raw => true)
        assert result.is_a?(Array)
      end
    end
    
  end
end
