require "test_helper"

class FactsTest < ActiveSupport::TestCase
  context "Facts" do
    setup do
      @facts = Class.new
      @facts.class_eval do
        def self.name; "MyFacts" end
        include Wonkavision::Analytics::Facts
        record_id :_id
        store :none

      end
    end

    should "configure an aggregation set" do
      assert_not_nil @facts.aggregations
    end

    should "present the configured record id" do
      assert_equal :_id, @facts.record_id
    end

    should "set the specified storage" do
      @facts.store :hash_store
      assert @facts.store.kind_of?(Wonkavision::Analytics::Persistence::HashStore)
      assert_equal @facts, @facts.store.owner
    end
  
    context "#facts_for" do
      should "pass arguments to underlying storage" do
        @facts.store :hash_store
        @facts.store.expects(:facts_for).with("agg",[:a,:b,:c],{})
        @facts.facts_for("agg",[:a,:b,:c])
      end
    end

  end
end
