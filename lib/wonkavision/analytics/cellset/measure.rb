module Wonkavision
  module Analytics
    class CellSet
      class Measure
        attr_reader :name, :data, :options, :default_component, :format, :schema, :cell
        def initialize(cell,name,data,measure_schema = nil)
          @cell = cell
          @name = name
          @data = data ? data.dup : {}
          @schema = measure_schema
          @options = @schema ? @schema.options : {}
          @default_component = @schema ? @schema.default_aggregation : :count
          @format = @schema ? @schema.format : nil
        end

        def to_s
          formatted_value
        end

        #options:
        #@format_measures, default = true, include a formatted_value
        #@all_measure_components, default = false, whether or not to include
        #the measure data hash, which will enable average, stdev, etc. regardless
        #of the default component.
        def serializable_hash(options={})
          hash = {
            :name => name,
            :value => empty? ? nil : value            
          }
          hash[:formatted_value] = empty? ? "" : formatted_value unless options[:format_measures] == false
          hash.merge!( {
            :data => data,
            :default_component => default_component
          }) if options[:all_measure_components] 
          hash
        end

        def inspect
          value
        end

        def formatted_value
          format.blank? || value.blank? ? value.to_s :
            StringFormatter.format(value, format, options)
        end

        def value
          if calculated?
            @schema.calculate!(self.cell)
          else
            send(@default_component)
          end
          #@has_value_field ? data["value"] : send(@default_component)
        end

        def calculated?
          @schema && @schema.calculated?
        end

        def empty?
          (count.nil? || count ==0) && !(calculated? && value)
        end

        def sum; empty? ? nil : @data["sum"]; end
        def count; @data["count"]; end
        def min; @data["min"];end
        def max; @data["max"];end

        def mean; empty? ? nil : sum/count; end
        alias :average :mean

        def aggregate(new_data)
          @data["sum"] = @data["sum"].to_f + new_data["sum"].to_f
          @data["count"] = @data["count"].to_i + new_data["count"].to_i
          @data["min"] = [@data["min"].to_f, new_data["min"].to_f].min
          @data["max"] = [@data["max"].to_f, new_data["max"].to_f].max
        end

        def method_missing(op,*args)
          args = [args[0].value.to_f] if args[0].kind_of?(Measure)
          args = args.map{|a|a.to_f}
          value.to_f.send(op,*args)
        end

      end
    end
  end
end
