require "set"

module Wonkavision
  module Analytics
    class CellSet
      attr_reader :axes, :query, :cells, :totals, :schema, :cube

      def initialize(schema,query,tuples)
        @axes = []
        @query = query
        @schema = schema
        @cube = @schema.cubes[query.from]
        @cells = {}
        @dimensions = query.selected_dimensions.map do |dimname|
          @cube.dimensions[dimname]
        end
        @dimension_fields = {}
        @measure_fields = {}

        dimension_members = process_tuples(tuples)

        start_index = 0
        query.axes.each do |axis_dimensions|
          @axes << Axis.new(self,axis_dimensions,dimension_members,start_index)
          start_index += axis_dimensions.length
        end

        calculate_totals

      end

      def columns; axes[0]; end
      def rows; axes[1]; end
      def pages; axex[2]; end
      def chapters; axes[3]; end
      def sections; axes[4]; end
     
      def selected_measures
        [:record] + @query.selected_measures
      end

      def inspect
        @cells.inspect
      end

      def to_s
        @cells.to_s
      end

      def serializable_hash(options={})
        {
          :axes => @axes.map { |axis| axis.serializable_hash( options ) },
          :cells =>
            @cells.values.map{ |cell| cell.serializable_hash( options ) },
          :totals => @totals ? @totals.serializable_hash( options ) : nil,
          :measure_names => selected_measures,
          :cube => cube.name,
          :slicer => @query.slicer.map{ |f| f.to_s },
          :filters => @query.filters.map{ |f| f.to_s }
        }
      end

      def [](*coordinates)
        coordinates.flatten!
        key = coordinates.map{ |c|c.nil? ? nil : c.to_s }
        @cells[key] || Cell.new(self,key,[],{})
      end

      def length
        @cells.length
      end

      private

      def calculate_totals(include_subtotals=false)
        cells.keys.each do |cell_key|
          measure_data = cells[cell_key].measure_data
          append_to_subtotals(measure_data,cell_key)
          @totals ? @totals.aggregate(measure_data) : @totals = Cell.new(self,[],[],measure_data)
        end
      end

      def append_to_subtotals(measure_data, cell_key)
        dims = []
        axes.each do |axis|
          axis.dimensions.each_with_index do |dimension, idx|
            dims << dimension.name
            sub_key = cell_key[0..dims.length-1]

            append_to_cell(dims.dup, measure_data, sub_key) if
              dims.length < cell_key.length #otherwise the leaf and already in the set

            #For axes > 0, subtotals must be padded with nil for all prior axes members
            if (axis.start_index > 0)
              axis_dims = dims[axis.start_index..axis.start_index + idx]
              axis_sub_key = Array.new(axis.start_index) +
                cell_key[axis.start_index..axis.start_index + idx]

              append_to_cell(axis_dims, measure_data, axis_sub_key)
            end

          end
        end
      end

      def process_tuples(tuples)
        dims = {}
        tuples.each do |record|
          update_cell( record )
          @dimensions.each do |d|
            dimdata = dimension_from_row(d, record)
            dim = dims[d.name.to_s] ||= {}
            dim_key = dimdata["key"]
            dim[dim_key] ||= dimdata
          end        
        end
        dims
      end

      def key_for(record)
        key = []
        @dimensions.each do |dim|
          key << record["#{dim.dimension.name}__key"]
        end
        key
      end

      def update_cell(record)
        dimensions = query.selected_dimensions
        cell_key ||= key_for(record)
        measure_data = measures_from_row(record)
        append_to_cell(dimensions, measure_data, cell_key)
      end

      def append_to_cell(dimensions, measure_data, cell_key)
        cell = cells[cell_key]
        cell ? cell.aggregate(measure_data) : cells[cell_key] = Cell.new(self,
                                                                         cell_key,
                                                                         dimensions,
                                                                         measure_data)
      end

      def measure_fields(measure_name, record)
        @measure_fields[measure_name] ||= begin
          prefix = /^#{measure_name}__/i
          record.keys.select{|rfield| rfield =~ prefix}
        end
      end

      def dimension_fields(dimension_name, record)
        @dimension_fields[dimension_name] ||= begin
          prefix = /^#{dimension_name}__/i
          record.keys.select{|dfield| dfield =~ prefix}
        end
      end

      def measures_from_row(record)
        measures = {}
        selected_measures.each do |measure_name|
          measure = {}
          measure_fields(measure_name, record).each do |measure_field|
            component_name = measure_field[measure_name.to_s.length+2..-1]
            measure[component_name] = record[measure_field]
          end
          measures[measure_name.to_s] = measure unless measure.blank?
        end
        measures
      end

      def dimension_from_row(dimension, record)
        dim = {}
        dimension_fields(dimension.name, record).each do |dimension_field|
          attribute_name = dimension_field[dimension.name.to_s.length+2..-1]
          dim[attribute_name.to_s] = record[dimension_field]
        end
        dim
      end

    end
  end
end
