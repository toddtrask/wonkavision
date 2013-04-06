require "test_helper"

class AggregationSpecTest < ActiveSupport::TestCase
  context "AggregationSpec" do
    setup do
      @aggregation_spec = Wonkavision::Analytics::Aggregation::AggregationSpec.new("MyAggregation")
    end

    should "take its name from the constructor" do
      assert_equal "MyAggregation", @aggregation_spec.name
    end

    should "include a default :count measure upon initialization" do
      assert_equal( {}, @aggregation_spec.measures[:count] )
    end


    context "#dimension" do
      setup do
        @aggregation_spec.dimension :a, :b, :c=>"d"
      end

      should "add a dimension for each provided value" do
        assert_equal 2, @aggregation_spec.dimensions.length
        ["a","b"].each { |dim| assert @aggregation_spec.dimensions.keys.include?(dim)}
      end

      should "store pass the options to each dimension" do
        @aggregation_spec.dimensions.values.each { |dim| assert_equal({:c=>"d"},dim.options)}
      end
    end

    context "#measure" do
      setup do
        @aggregation_spec.measure :c, :d, :e => "f"
      end

      should "add a measure for each provided value (plus the default :count)" do
        assert_equal 3, @aggregation_spec.measures.length
      end

      should "add the attributes as hash elements" do
        [:c, :d].each { |measure| assert @aggregation_spec.measures[measure]}
      end

      should "store the options to each measure" do
        @aggregation_spec.measures.each_pair { |k,v| assert_equal({ "e" => "f"}, v) unless
          k == "count"}
      end
    end

    context "#calc" do
      setup do
        @aggregation_spec.calc :calculated do
          c + d
        end
      end
      should "add a calculated measure" do
        assert_equal 1, @aggregation_spec.calculated_measures.length
      end
      should "be stored by name" do
        assert_equal "calculated", @aggregation_spec.calculated_measures.keys[0]
      end
      should "store the provided block in the options" do
        assert @aggregation_spec.calculated_measures[:calculated][:calculation].kind_of?(Proc)
      end
    end
    
    context "measure aliases" do
      should "call measure with an appropriate default component specified" do
        [:average,:sum,:count].each do |m_alias|
          @aggregation_spec.send(m_alias,:my_measure)
          assert_equal m_alias, @aggregation_spec.measures[:my_measure][:default_component]
        end
      end

    end

    context "#filter" do
      setup do
        @aggregation_spec.filter { |msg|msg["a"] == "b"}
      end
      should "register a filter block with the spec" do
        assert_not_nil @aggregation_spec.filter
      end
    end
    context "#matches" do
      setup do
        @aggregation_spec.filter { |msg| msg["a"] == "b"}
      end
      should "return true if a message matches the filter" do
        assert @aggregation_spec.matches({ "a" => "b"})
      end
      should "return false if the message does not match the filter" do
        assert !@aggregation_spec.matches({ "a" => "B"})
      end
    end

  end
end
