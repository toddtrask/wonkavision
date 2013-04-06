require "test_helper"

class AttributeTest < ActiveSupport::TestCase
  context "Attribute" do
    setup do
      @attribute = Wonkavision::Analytics::Schema::Attribute.new(:dimension, :my_attribute,:an_option=>true)
    end

    should "take its name from the constructor" do
      assert_equal :my_attribute, @attribute.name
    end

    should "take its options from the constructor" do
      assert_equal( { :an_option => true}, @attribute.options )
    end

    should "store the provided dimension" do
      assert_equal :dimension, @attribute.dimension
    end


  end
end
