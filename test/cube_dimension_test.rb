require "test_helper"
require File.join $test_dir, "test_schema.rb"


class CubeDimensionTest < ActiveSupport::TestCase
  context "CubeDimension" do
    setup do
      @cube = RevenueAnalytics.cubes[:transport]
      @dim = Wonkavision::Analytics::Schema::CubeDimension.new(@cube, :my_provider,:as=>:provider)
    end

    should "store the cube" do
      assert_equal @cube, @dim.cube
    end

    should "take its name from the constructor" do
      assert_equal :my_provider, @dim.name
    end

    should "take its options from the constructor" do
      assert_equal( { :as => :provider}, @dim.options )
    end

    should "create a default foreign key" do
      assert_equal "my_provider_key", @dim.foreign_key
    end

    should "reference the parent dimension" do
      assert_equal RevenueAnalytics.dimensions[:provider], @dim.dimension
    end
  end
end
