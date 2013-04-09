require "test_helper"

class StoreTest < ActiveSupport::TestCase
  Store = Wonkavision::Analytics::Persistence::Store

  context "Store" do
    setup do
      @store = Store.new(RevenueAnalytics)
    end

    context "Public api" do
      context "#facts_for" do
        setup do
          Wonkavision::Analytics.context.global_filters <<  :dimensions.a.eq(:b)
        end
        teardown do
          Wonkavision::Analytics.context.global_filters.clear
        end
        should "append global filters and call fetch_facts" do
          @store.expects(:fetch_facts).with(:hi,[:a,:dimensions.a.eq(:b)],{ })
          @store.facts_for(:hi, [:a])
        end
      end

    
      context "Deriving from Store" do
        should "register the derived class with the superclass" do
          class NewStore < Store; end
          assert_equal NewStore, Store[:new_store]
        end
      end
    end

  end
end
