require "test_helper"
require File.join $test_dir, "test_schema.rb"

class CubeTest < ActiveSupport::TestCase
  context "Cube" do
    setup do
      @cube = Wonkavision::Analytics::Schema::Cube.new(RevenueAnalytics, :acube, :hi=>:ho) do
        dimension :dim1
        measure :m1
        sum :m2
        average :m3
        count :m4
      end
    end

    should "store the schema" do
      assert_equal RevenueAnalytics, @cube.schema
    end

    should "set the name" do
      assert_equal :acube, @cube.name
    end

    should "set the options" do
      assert_equal( {:hi=>:ho}, @cube.options )
    end

    should "create and store dimensions" do
      assert_equal :dim1, @cube.dimensions[:dim1].name
    end

    should "create and store measures" do
      assert_equal :m1, @cube.measures[:m1].name
    end

    should "create and configure sum measures" do
      assert_equal :sum, @cube.measures[:m2].default_aggregation
    end

    should "create and configure average measures" do
      assert_equal :average, @cube.measures[:m3].default_aggregation
    end

    should "create and configure count measures" do
      assert_equal :count, @cube.measures[:m4].default_aggregation
    end

    should "default to a conventional key name" do
      assert_equal "acube_key", @cube.key
    end

    should "allow the key to be set" do
      @cube.key "adifferentkey"
      assert_equal "adifferentkey", @cube.key
    end

  end
end
