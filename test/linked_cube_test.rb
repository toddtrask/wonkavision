require "test_helper"
require File.join $test_dir, "test_schema.rb"


class LinkedCubeTest < ActiveSupport::TestCase
  context "LinkedCube" do
    setup do
      @cube = RevenueAnalytics.cubes[:account_state]
      @link = @cube.linked_cubes[:transport]
      @link2 = @cube.linked_cubes[:transport2]
    end

    should "store the cube" do
      assert_equal @cube, @link.cube
    end

    should "take its name from the constructor" do
      assert_equal :transport, @link.name
    end

    should "store the join_on criteria" do
      assert_equal( {:provider_key=>:provider_key, :account_call_number=>:account_call_number}, @link.join_on )
    end

    should "create a default join_on based on the foreign key" do
      assert_equal( {:account_key => :account_key}, @link2.join_on)
    end


  end
end
