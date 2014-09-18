require "test_helper"
require File.join $test_dir, "test_schema.rb"

class DimensionTest < WonkavisionTest

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
        assert_equal nil, @dimension.sort
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
        should "return nil if no sort defined" do
          @dimension.sort = nil
          assert_equal nil, @dimension.sort
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
        should "return nil if no caption is defined" do
          @dimension.caption = nil
          assert_equal nil, @dimension.caption
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
      
      end

      context "#table_name" do
        should "return the default table name" do
          assert_equal "dim_hi", @dimension.table_name
        end
        should "return an alternative table name when set" do
          @dimension.table_name "wakka"
          assert_equal "wakka", @dimension.table_name
        end
      end

      context "#is_derived" do
        should "be false by default" do
          assert_equal false, @dimension.is_derived?
        end
        should "reference itself as the source dimension" do
          assert_equal @dimension, @dimension.source_dimension
        end
      end

      context "derived dimensions" do
        setup do
          @dimension.derived_from :payer
        end
        should "appear as derived" do
          assert_equal true, @dimension.is_derived?
        end
        should "link to the source dimension" do
          assert_equal RevenueAnalytics.dimensions[:payer], @dimension.source_dimension
        end
        should "present the source dimensions table name" do
          assert_equal "dim_payer", @dimension.table_name
        end
      end

      context "calculated attributes" do
        setup do
          @dimension.calculate :calced, "current_timestamp"
          @dimension.calculate :calced2, "get_date()"
        end
        should "create an attribute with appropriate expression" do
          assert_equal("current_timestamp",@dimension.attributes[:calced].expression)
          assert_equal("get_date()",@dimension.attributes[:calced2].expression)
        end
        context "#calculated_attributes" do
          should "return calculated attributes" do
            assert_equal 2, @dimension.calculated_attributes.length
          end
        end
        context "#has_calculated_attributes" do
          should "be true when there are calculated attributes" do
            assert_equal true, @dimension.has_calculated_attributes?
          end
        end
        context "#table_name" do
          should "return the name of the dimension" do
            assert_equal "hi", @dimension.table_name
          end
        end
      end

    end

  end
end
