module Wonkavision
  module Analytics
    class DimensionQuery
      attr_reader :attributes, :order

      def initialize(&block)
        @filters = []
        @order = []
        @attributes =[]
        @from = nil
        if block
          block.arity == 1 ? block.call(self) : self.instance_eval(&block)
        end
      end

      def from(dimension_name=nil)
        return @from unless dimension_name
        @from = dimension_name.to_s.to_sym
        self
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

      def where(criteria_hash = {})
        criteria_hash.each_pair do |filter,value|
          member_filter = to_filter(filter, value)
          add_filter(member_filter)
        end
        self
      end

      def filters()
        filterlist = @filters
        filterlist.compact.uniq
      end


      def add_filter(member_filter)
        @filters << member_filter
        self
      end

      def validate!(schema)
        raise "You must specify a 'from' dimension in your query" unless @from
        raise "The specified dimension #{@from} does not exist" unless dimension = schema.dimensions[@from]
        filters.each{|filter| raise "Dimension filters must apply to the dimension being queried, which in this case id #{@from}. You attempted to add a filter for #{filter.name} however." unless filter.name.to_s == from.to_s}
        true
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
