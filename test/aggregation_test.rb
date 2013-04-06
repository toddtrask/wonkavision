require "test_helper"

class AggregationTest < ActiveSupport::TestCase
  context "Aggregation" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts"; end
        include Wonkavision::Analytics::Facts
      end

      @agg = Class.new
      @agg.class_eval do
        def self.name; "MyAggregation"; end
        include Wonkavision::Analytics::Aggregation
        dimension :a, :b, :c

        dimension :complex do
          key :cpx
        end

        measure :d
        store :hash_store
      end
      @agg.aggregates @facts

    end

    should "configure a specification" do
      assert_not_nil @agg.aggregation_spec
    end

    should "set the name of the aggregation to the name of the class" do
      assert_equal @agg.name, @agg.aggregation_spec.name
    end

    should "proxy relevant calls to the specification" do
      assert_equal @agg.dimensions, @agg.aggregation_spec.dimensions
      assert_equal 4, @agg.dimensions.length
    end

    should "create complex dimensions" do
      assert_equal :cpx, @agg.dimensions[:complex].key
    end

    should "register itself with the module" do
      assert_equal @agg, Wonkavision::Analytics::Aggregation.all[@agg.name]
    end

    should "set the aggregates property" do
      assert_equal @facts, @agg.aggregates
    end
    
    should "register itself with its associated Facts class" do
      assert_equal 1, @facts.aggregations.length
      assert_equal @agg, @facts.aggregations[0]
    end

    should "set the specified storage" do
      assert @agg.store.kind_of?(Wonkavision::Analytics::Persistence::HashStore)
      assert_equal @agg, @agg.store.owner
    end

    should "manage a list of cached instances keyed by dimension hashes" do
      instance = @agg[{ "a" => { "a"=>:b}}]
      assert_not_nil instance
      assert_equal instance, @agg[{ "a" => { "a"=>:b}}]
      assert_not_equal instance, @agg[{  "a" => { "a"=>:b},  "b" => { "b"=>:c}}]
    end

    should "store the dimension list with the instance" do
      instance = @agg[{ "a" => { "a"=>:b}}]
      assert_equal( { "a" => { "a"=>:b}}, instance.dimensions )
    end

    context "#query" do
      should "create a new query" do
        assert @agg.query(:defer=>true).kind_of?(Wonkavision::Analytics::Query)
      end
      should "apply a provided block to the query" do
        assert_equal [:a], @agg.query(:defer=>true){ select :a }.selected_dimensions
      end
      should "raise an error if the query is invalid" do
        assert_raise(RuntimeError) { @agg.query{ select :a, :on => :rows} }
      end
      should "execute the query against the configured store" do
        @agg.store.expects(:execute_query).returns([])
        @agg.query
      end
      should "return a cellset based on the query results" do
        @agg.store.expects(:execute_query).returns([])
        assert @agg.query.kind_of?(Wonkavision::Analytics::CellSet)
      end
    end

    context "#facts_for" do
      should "pass the request to the underlying Facts class" do
        @facts.expects(:facts_for).with(@agg, [:a,:b,:c],{})
        @agg.facts_for([:a,:b,:c])
      end
    end

    context "instance methods" do
      setup do
        @instance = @agg[{ "a" => { "a"=>:b}}]
      end

      context "#dimension_names" do
        should "present dimension names as an array" do
          assert_equal ["a"], @instance.dimension_names
        end
      end

      context "#dimension_keys" do
        should "present dimension keys as an array" do
          assert_equal [:b], @instance.dimension_keys
        end
      end  

    end
  end
end
