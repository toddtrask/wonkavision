require "test_helper"
require File.join $test_dir, "test_schema.rb"


class MeasureTest < ActiveSupport::TestCase
  context "Measure" do
    setup do
      @cube = RevenueAnalytics.cubes[:transport]
      @m = Wonkavision::Analytics::Schema::Measure.new(@cube, :measure, :format=>:hi, :precision=>:ho)
    end

    should "store the cube" do
      assert_equal @cube, @m.cube
    end

    should "take its name from the constructor" do
      assert_equal :measure, @m.name
    end

    should "store its options from the constructor, except format" do
      assert_equal( { :precision => :ho}, @m.options )
    end

    should "default its aggregation to sum" do
      assert_equal :sum, @m.default_aggregation
    end

    should "take the format from the constructor" do
      assert_equal :hi, @m.format
    end

    should "be able to set the format with options" do
      @m.format(:fmt, :fmt_opt=>1)
      assert_equal( {:precision=>:ho, :fmt_opt=>1}, @m.options )
      assert_equal :fmt, @m.format
    end

  end

  context "Calculated Measure" do
    setup do
      @cube = RevenueAnalytics.cubes[:transport]
      @m = Wonkavision::Analytics::Schema::Measure.new(@cube, :measure, :calculation=>proc{length/2})
    end

    should "id itself as calculated" do
      assert_equal true, @m.calculated?
    end

    should "execute the calculation based on the context" do
      assert_equal 4/2, @m.calculate!(["hi","ho","hum","ha"])
    end
  end
end
