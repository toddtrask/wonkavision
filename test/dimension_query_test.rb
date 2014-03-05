require "test_helper"

class DimensionQueryTest < Test::Unit::TestCase
  DimensionQuery = Wonkavision::Analytics::DimensionQuery

  context "Query" do
    setup do
      @query = DimensionQuery.new
    end

    context "#where" do
      should "convert a symbol to a MemberFilter" do
        @query.where :a=>:b
        assert @query.filters[0].kind_of?(Wonkavision::Analytics::MemberFilter)
      end

      should "append filters to the filters array" do
        @query.where :a=>:b, :c=>:d
        assert_equal 2, @query.filters.length
      end

      should "set the member filters value from the hash" do
        @query.where :a=>:b
        assert_equal :b, @query.filters[0].value
      end

    end
   
    context "validate!" do
      should "not fail a valid query" do
        @query.from :division
        @query.where(:division => 1)
        @query.attributes :division.caption
        @query.validate!(RevenueAnalytics)
      end
      should "fail unless from is specified" do
        assert_raise(RuntimeError){@query.validate!(RevenueAnalytics)}
      end
      should "fail without a valid from" do
        @query.from :not_a_dimension
        assert_raise(RuntimeError){@query.validate!(RevenueAnalytics)}
      end
      should "fail if an invalid dimension filter is specified" do
        @query.from :division
        @query.where :dimensions.provider.gt => 1
        assert_raise(RuntimeError){@query.validate!(RevenueAnalytics)}
      end
    

    end

  end
end
