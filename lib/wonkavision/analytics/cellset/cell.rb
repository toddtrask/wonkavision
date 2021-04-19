module Wonkavision
  module Analytics
    class CellSet
      class Cell
        attr_reader :key, :measures, :dimensions, :cellset

        def initialize(cellset,key,dims,measure_data)
          @cellset = cellset
          @filters_val = nil
          @key = key
          @dimensions = dims
          @measures = HashWithIndifferentAccess.new
          measure_data.each_pair do |measure_name,measure|
            measure_schema = cellset.cube.measures[measure_name]
            @measures[measure_name] = Measure.new(self, measure_name,measure,measure_schema)
          end
          #add in any calculated measures that may not have data represented
          cellset.selected_measures.each do |measure_name|
            m_schema = cellset.cube.measures[measure_name]
            unless @measures[measure_name]
              @measures[measure_name] = Measure.new(self, measure_name,{}, m_schema)
            end
          end
          # calculated_measures.each_pair do |measure_name, calc|
          #   @measures[measure_name] = CalculatedMeasure.new(measure_name,self,calc)
          # end
        end

        def serializable_hash(options={})
          #ensure calculated measures are added to the measures
          #hash
          #calculated_measures.keys.each {|name|self[name]}
          {
            :key => key,
            :dimensions => dimensions,
            :measures => measures.inject([]) do |output, (_ , measure)|
              (output << measure.serializable_hash(options)) if cellset.is_measure_selected?(measure.name)
              output
            end
          }
        end

        def measure_data
          measure_data = {}
          measures.each_pair do |key,value|
            measure_data[key] = value.data unless value.calculated?
          end
          measure_data
        end

        def aggregate(measure_data)
          measure_data.each_pair do |measure_name,measure_data|
            measure = @measures[measure_name]
            measure ? measure.aggregate(measure_data) :
              @measures[measure_name] = Measure.new(self,measure_name,measure_data)
          end
        end

        # def calculated_measures
        #   cellset.aggregation.calculated_measures
        # end

        def [](measure_name)
          unless measures.keys.include?(measure_name.to_s)
            Measure.new(self,measure_name, {})
          else
            measures[measure_name]
          end
        end

        def method_missing(method,*args)
          self[method]
        end

        def empty?
          measure_data.blank? || measures.values.detect{ |m| !m.empty? }.nil?
        end

        def to_s
          "<Cell #{@key.inspect}>"
        end

        def inspect
          to_s
        end

        def filters
          unless @filters_val
            @filters_val = []
            dimensions.each_with_index do |dim_name, index|
              @filters_val << MemberFilter.new( dim_name, :value => key[index] )
            end
            @filters_val += cellset.query.filters(false)
          end
          @filters_val
        end
      end
    end
  end
end
