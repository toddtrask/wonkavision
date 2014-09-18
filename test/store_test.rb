require "test_helper"

class StoreTest < WonkavisionTest
  Store = Wonkavision::Analytics::Persistence::Store

  context "Store" do
    setup do
      @store = Store.new(RevenueAnalytics)
    end

    context "Public api" do
      context "Deriving from Store" do
        should "register the derived class with the superclass" do
          class NewStore < Store; end
          assert_equal NewStore, Store[:new_store]
        end
      end
    end

  end
end
