require "test_helper"
require "wonkavision/api/helper"

class ApiHelperTest < ActiveSupport::TestCase
  setup do
    @helper = Wonkavision::Api::Helper.new(RevenueAnalytics)
  end

  context "#query_from_params" do
    setup do
      @params = {
        "from" => "transport",
        "columns" => "a|b",
        "rows" => "c|d ", 
        "pages" => ["e","f"],
        "chapters" => ["g","h"],
        "sections" => ["i","j"],
        "measures" => ["k","l"],
        "filters" => [:dimensions.a.caption.eq(2).to_s, :measures.k.ne("b").to_s].join("|"),
        "attributes" => [:dimensions.a.key.to_s, :measures.k.to_s],
        "order" => [:dimensions.b.key.asc.to_s, :measures.c.asc.to_s]
      }
      @query = @helper.query_from_params(@params)

    end

    should "set select the cube using the from param" do
      assert_equal "transport", @query.from
    end
    
    should "extract dimensions into each named axis" do
      (0..4).each do |axis_ordinal|
        ["columns","rows","pages","chapters","sections"].each_with_index do |axis,idx|
          assert_equal @helper.parse_list(@params[axis]), @query.axes[idx]
        end
      end
    end

    should "extract measures" do
      assert_equal @params["measures"], @query.measures
    end

    should "extract each filter" do
      assert_equal 2, @query.filters.length
    end

    should "convert strings to MemberFitler" do
      @query.filters.each do |f|
        assert f.kind_of?(Wonkavision::Analytics::MemberFilter)
      end
    end

    should "properly parse each filter" do
      assert_equal :dimension, @query.filters[0].member_type
      assert_equal :eq, @query.filters[0].operator
      assert_equal 2, @query.filters[0].value
      assert_equal 'caption', @query.filters[0].attribute_name

      assert_equal :measure, @query.filters[1].member_type
      assert_equal :ne, @query.filters[1].operator
      assert_equal "b", @query.filters[1].value
      assert_equal 'count', @query.filters[1].attribute_name
    end

    should "extract attributes" do
      assert_equal 2, @query.attributes.length
      @query.attributes.each do |f|
        assert f.kind_of?(Wonkavision::Analytics::MemberReference)
      end
    end

    should "extract sorts" do
      assert_equal 2, @query.order.length
      @query.order.each do |s|
        assert s.kind_of?(Wonkavision::Analytics::MemberReference)
      end
    end
  end

  context "execute_query" do
    setup do
      cs = stub(:serializable_hash => :hash)
      @helper.expects(:query_from_params).with({:from=>"transport"}).returns(:hi)
      RevenueAnalytics.expects(:execute_query).with(:hi).returns(cs)
    end
    should "prepare and execute the query defined in the params" do
      assert_equal :hash, @helper.execute_query({:from=>"transport"})
    end
  end

  context "facts_for" do
    setup do
      result = {:some=>:data}
      class << result; include Wonkavision::Analytics::Paginated; end

      query = {}
      query.expects(:from).returns(:transport)
      @helper.expects(:query_from_params).
        with(:from=>"transport", :page=>2).
        returns(query)
       RevenueAnalytics.expects(:facts_for).with(query,{:page=>2}).returns(result)
       @response = @helper.facts_for({:from=>"transport", :page=>2})
    end
    should "set the cube name" do
      assert_equal :transport, @response[:cube]
    end
    should "return the data" do
      assert_equal( {:some=>:data}, @response[:data] )
    end
    should "include pagination data" do
      assert @response[:pagination]
    end
  end

  context "parse_list" do
    should "should return nil if the input is blank" do
      assert_equal nil, @helper.parse_list("")
    end
    should "return an array if the input is an array" do
      assert_equal [1,2,3], @helper.parse_list([1,2,3])
    end
    should "return a single element array if the input is a single string" do
      assert_equal ["a"], @helper.parse_list("a")
    end
    should "split a string by commas if the input is a comma string" do
      assert_equal ["a","b","c"], @helper.parse_list("a| b |   c   ")
    end
  end


end
