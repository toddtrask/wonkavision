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
      assert_equal 1, RevenueAnalytics.cubes.length
      assert RevenueAnalytics.cubes.values[0].is_a?(Wonkavision::Analytics::Schema::Cube)
    end

    should "set the specified storage" do
      assert RevenueAnalytics.store.kind_of?(Wonkavision::Analytics::Persistence::ActiveRecordStore)
      assert_equal RevenueAnalytics, RevenueAnalytics.store.schema
    end
    
  end
end
