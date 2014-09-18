require "test_helper"

class AttributeTest < Test::Unit::TestCase
  context "Attribute" do
    setup do
      @attribute = Wonkavision::Analytics::Schema::Attribute.new(:dimension, :my_attribute,:an_option=>true, :expression=>:expression)
    end

    should "take its name from the constructor" do
      assert_equal :my_attribute, @attribute.name
    end

    should "take its options from the constructor" do
      assert_equal( { :an_option => true}, @attribute.options.slice(:an_option) )
    end

    should "store the provided dimension" do
      assert_equal :dimension, @attribute.dimension
    end

    should "store the provided expression" do
      assert_equal :expression, @attribute.expression
    end

    should "indicate when calculated" do
      assert_equal true, @attribute.calculated?
    end


  end
end
