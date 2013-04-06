require "test_helper"
require File.join $test_dir, "test_schema.rb"

class DimensionTest < ActiveSupport::TestCase

  Dimension = Wonkavision::Analytics::Schema::Dimension

  context "Dimension" do
    context "Basic Initialization" do
      setup do
        @dimension = Dimension.new RevenueAnalytics, :hi, :option=>true
      end

      should "take its name from the constructor" do
        assert_equal :hi, @dimension.name
      end

      should "take its options from the constructor" do
        assert_equal( { :option => true}, @dimension.options )
      end

      should "default the key sort and caption properties to name" do
        assert_equal "hi_key", @dimension.key.name
        assert_equal "hi_key", @dimension.sort.name
        assert_equal "hi_name", @dimension.caption.name
      end

      should "create an attribute for the key and name" do
        assert_equal 2, @dimension.attributes.length
        assert @dimension.attributes[:hi_key]
        assert @dimension.attributes[:hi_name]
      end

    end
    context "When initialized via options" do
      setup do
        @dimension = Dimension.new RevenueAnalytics, :hi, :key=>:k, :sort => :s, :caption => :c
      end

      should "set the special attribute properties from the options" do
        assert_equal :k, @dimension.key.name
        assert_equal :s, @dimension.sort.name
        assert_equal :c, @dimension.caption.name
      end

      should "create attributes for each attribute property" do
        assert_equal 3, @dimension.attributes.length
        assert @dimension.attributes[:k]
        assert @dimension.attributes[:s]
        assert @dimension.attributes[:c]
      end
    end

    context "when initialized via block" do
      setup do
        @dimension = Dimension.new RevenueAnalytics, :hi do
          key :k, :key_option=>true
          sort :s, :sort_option=>true
          caption :c, :caption_option=>true
          attribute :a, :attribute_option=>true
        end
      end
      should "set the special attribute properties from theblock" do
        assert_equal :k, @dimension.key.name
        assert_equal :s, @dimension.sort.name
        assert_equal :c, @dimension.caption.name
      end
      should "create attributes for each attribute and attribute property" do
        assert_equal 4, @dimension.attributes.length
        assert @dimension.attributes[:k]
        assert @dimension.attributes[:s]
        assert @dimension.attributes[:c]
        assert @dimension.attributes[:a]
      end
    end

    context "DSL methods" do
      setup do
        @dimension = Dimension.new RevenueAnalytics, :hi
      end
      context "#attribute" do
        setup do
          @dimension.attribute :a, :c=>:d, :e=>:f
        end
        should "create an attribute for each non-option argument" do
          #assert 3 because the key  and name attributes are always present
          assert_equal 3, @dimension.attributes.length
          assert @dimension.attributes[:a]
        end
        should "pass along options to each created attribute" do
          assert_equal( { :c=>:d, :e=>:f}, @dimension.attributes[:a].options )
        end
      end

      context "#sort" do
        setup do
          @dimension.sort :s, :option=>true
        end
        should "set the sort property to the provided value" do
          assert_equal :s, @dimension.sort.name
        end
        should "create an attribute for the sort key if not present" do
          assert @dimension.attributes[:s]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:s].options)
        end
        should "return the key if no sort is defined" do
          @dimension.sort = nil
          assert_equal @dimension.key, @dimension.sort
        end
        should "not re-create a pre-existing attribute" do
          @dimension.sort :s, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:s].options )
        end
      end

      context "#caption" do
        setup do
          @dimension.caption :c, :option=>true
        end
        should "set the caption property to the provided value" do
          assert_equal :c, @dimension.caption.name
        end
        should "create an attribute for the caption key if not present" do
          assert @dimension.attributes[:c]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:c].options)
        end
        should "return the key if no caption is defined" do
          @dimension.caption = nil
          assert_equal @dimension.key, @dimension.caption
        end
        should "not re-create a pre-existing attribute" do
          @dimension.caption :c, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:c].options )
        end
      end

      context "#key" do
        setup do
          @dimension.key :k, :option=>true
        end
        should "set the key property to the provided value" do
          assert_equal :k, @dimension.key.name
        end
        should "create an attribute for the key if not present" do
          assert @dimension.attributes[:k]
        end
        should "pass options to the created attribute" do
          assert_equal({ :option=>true }, @dimension.attributes[:k].options)
        end
        should "not re-create a pre-existing attribute" do
          @dimension.key :k, :option=>false
          assert_equal( { :option => true},  @dimension.attributes[:k].options )
        end
      end

    end

  end
end
