class TestFacts
  include Wonkavision::Analytics::Facts
end

class TestAggregation
  include Wonkavision::Analytics::Aggregation

  aggregates TestFacts
  
  store :hash_store

  dimension :color, :size, :shape
  measure :weight, :default_to=>:average, :format=>:float,:precision=>2
  measure :cost, :default_to=>:sum, :format=>:float, :precision=>1

  calc :cost_weight do
    cost + weight.sum
  end
  
end

module Ns
  class Aggregation < ::TestAggregation
  end

  class TestFacts < ::TestFacts
  end
end
