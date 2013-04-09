require "test_helper"
require "cgi"

class MemberFilterTest < ActiveSupport::TestCase
  context "MemberFilter" do
    setup do
      @dimension = Wonkavision::Analytics::MemberFilter.new(:a_dim,   :member_type=>:dimension)
      @measure = Wonkavision::Analytics::MemberFilter.new(:a_measure, :member_type=>:measure)
    end
    context "#attribute_name" do
      should "default to key for dimension" do
        assert_equal :key, @dimension.attribute_name
      end
      should "default to count for measure" do
        assert_equal :count, @measure.attribute_name
      end
    end
    context "#dimension?" do
      should "be true for dimension" do
        assert @dimension.dimension?
      end
      should "not be true for measure" do
        assert !@measure.dimension?
      end
    end
    context "#measure?" do
      should "be true for measure" do
        assert @measure.measure?
      end
      should "not be true for dimension" do
        assert !@dimension.measure?
      end
    end
    context "#operators" do
      should "set the operator property appropriately" do
        [:gt, :lt, :gte, :lte, :ne, :in, :nin].each do |op|
          assert_equal op, @dimension.send(op).operator
        end
      end
    end

  
     context "#to_s" do
      should "produce a canonical string representation of a member filter" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).eq(3)
        assert_equal "dimension::hi::key::eq::3", filter.to_s
      end
      should "should be 'parse'able to reproduce the filter" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).eq(3)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s)
        assert_equal filter, filter2
      end
      should "wrap strings in a single quote" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).ne("whatever")
        assert_equal "dimension::hi::key::ne::'whatever'", filter.to_s
      end
      should "be able to represent a parseable time as a filter value" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(Time.now)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s)
        assert_equal filter, filter2
      end
      should "omit the value portion of the string when requested" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        assert_equal "dimension::hi::key::gt", filter.to_s(:exclude_value=>true)
      end
      should "be able to parse a value-less emission" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s(:exclude_value=>true))
        assert_nil filter2.value
        filter2.value = 5
        assert_equal filter, filter2
      end
      should "take its value from an option on parse" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi).gt(5)
        filter2 = Wonkavision::Analytics::MemberFilter.parse(filter.to_s(:exclude_value=>true),
                                                             :value=>5)
        assert_equal filter, filter2
      end
      should "return just a name with name_only is true" do
        filter = Wonkavision::Analytics::MemberFilter.new(:hi)
        assert_equal "dimension::hi::key", filter.to_s(:name_only=>true)
        assert_equal filter.qualified_name, filter.to_s(:name_only=>true)
      end

    end
    context "#parse" do
      should "properly extract an array wrapped in a string" do
        filter_string = "dimension::company_id::key::in::'[\"4d38c63d0c7dea49e0000005\", \"4d1bb6290c7dea787f0000d6\"]'"
        filter = Wonkavision::Analytics::MemberFilter.parse(filter_string)
        assert_equal ["4d38c63d0c7dea49e0000005", "4d1bb6290c7dea787f0000d6"], filter.value
      end
    end


  end
end
