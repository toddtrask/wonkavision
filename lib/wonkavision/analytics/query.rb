module Wonkavision
  module Analytics
    class Query
      attr_reader :axes, :measures, :attributes, :order, :top_filter

      def initialize(&block)
        @axes = []
        @filters = []
        @measures = []
        @order = []
        @attributes =[]
        @from = nil
        @top_filter = nil
        if block
            block.arity == 1 ? block.call(self) : self.instance_eval(&block)
        end
      end

      def from(cube_name=nil)
        return @from unless cube_name
        @from = cube_name
        self
      end

      def select(*dimensions)
        options = dimensions.extract_options!
        axis = options[:axis] || options[:on]
        axis_ordinal = self.class.axis_ordinal(axis)
        @axes[axis_ordinal] = dimensions.flatten
        self
      end

      [:columns,:rows,:pages,:chapters,:sections].each do |axis|
        eval "def #{axis}(*args);args.add_options!(:axis=>#{axis.inspect});select(*args);end"
      end

      def measures(*measures)
        @measures.concat measures.flatten
      end

      def order(*attributes)
        return @order unless attributes.length > 0
        attributes.each do |order|
          @order << to_ref(order)
        end
        self
      end

      def attributes(*attributes)
        return @attributes unless attributes.length > 0
        attributes.each do |attribute|
          @attributes << to_ref(attribute)
        end
        self
      end

      def top(num, dimension, options={})
        filters = options[:filters].map{|f|to_filter(f)} if options[:filters]
        filters ||= (options[:where] || {}).map{|f,v| to_filter(f,v)}
        @top_filter = {
          :count => num,
          :dimension => dimension.to_sym,
          :measure => options[:by] || options[:measure],
          :exclude => [options[:exclude]].flatten.compact.map{|d|d.to_sym},
          :filters => filters
        }
      end

      def where(criteria_hash = {})
        criteria_hash.each_pair do |filter,value|
          member_filter = to_filter(filter, value)
          add_filter(member_filter)
        end
        self
      end

      def filters(include_global=true)
        filterlist = @filters
        filterlist += Wonkavision::Analytics.context.global_filters if include_global
        filterlist.compact.uniq
      end


      def add_filter(member_filter)
        @filters << member_filter
        self
      end

      def slicer
        filters.select{|f|f.dimension?}.reject{|f|selected_dimensions.include?(f.name.to_sym)}.compact.uniq
      end

      def slicer_dimensions
        unique_list slicer.map{ |f|f.name }
      end

      def referenced_dimensions
        unique_list(
            [] +
            selected_dimensions.map{|s|s} +
            slicer.map{|f|f.name} + 
            attributes.select{|a|a.dimension?}.map{|a|a.name} 
        )
      end

      def referenced_facts
        unique_list(
          order.select{|a|a.fact?}.map(&:name) + 
          attributes.select{|a|a.fact?}.map(&:name) +
          filters.select{|f|f.fact?}.map(&:name)
        ) - [from.to_sym]
      end


      def selected_dimensions
        dimensions = []
        axes.each { |dims|dimensions.concat(dims) unless dims.blank? }
        dimensions.concat attributes.select{|a|a.dimension?}.map{|a|a.name}
        unique_list dimensions
      end

      def all_dimensions?
        axes.empty?
      end

      def selected_measures
        @measures.blank? ? [:record_count] : @measures
      end

      def matches_filter?(cube, tuple)
        !( filters.detect{ |filter| !filter.matches(cube, tuple) } )
      end

      def validate!(schema)
        raise "You must specify a 'from' cube in your query" unless @from
        raise "The specified cube (#{@from} does not exist" unless cube = schema.cubes[@from]
        axes.each_with_index{|axis,index|raise "Axes must be selected from in consecutive order and contain at least one dimension. Axis #{index} is blank." if axis.blank?}
        selected_measures.each{|measure_name|raise "The measure #{measure_name} cannot be found in #{cube.name}" unless cube.measures[measure_name]}
        raise "No dimensions were selected" unless selected_dimensions.length > 0
        selected_dimensions.each{|dim_name| raise "The dimension #{dim_name} cannot be found in #{cube.name}" unless cube.dimensions[dim_name]}
        filters.each{|filter| raise "A filter referenced an invalid member:#{filter.to_s}" unless filter.validate!(cube)}
        true
      end     

      def self.axis_ordinal(axis_def)
        case axis_def.to_s.strip.downcase.to_s
        when "columns" then 0
        when "rows" then 1
        when "pages" then 2
        when "chapters" then 3
        when "sections" then 4
        else axis_def.to_i
        end
      end

      private
      def unique_list(list = [])
        list.compact.map(&:to_sym).uniq
      end

      def to_ref(ref_or_string, default_type = :dimension)
        return nil unless ref_or_string.present?
        ref_or_string.kind_of?(MemberReference) ? ref_or_string : MemberReference.new(ref_or_string, :member_type => default_type)
      end

      def to_filter(filter_or_string, value = nil)
        return nil unless filter_or_string.present?
        filter = filter_or_string.kind_of?(MemberFilter) ? filter_or_string : MemberFilter.new(filter_or_string)
        filter.value = value unless value.blank?
        filter
      end

    end
  end
end
