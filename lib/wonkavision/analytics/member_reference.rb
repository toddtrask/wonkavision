module Wonkavision
  module Analytics
    class MemberReference
      include Comparable

      attr_reader :name, :member_type, :order

      def initialize(member_name, options = {})
        @name = member_name
        @attribute_name = options[:attribute_name]
        @member_type = options[:member_type] || :dimension
        @order = :asc
      end

      def attribute_name
        @attribute_name ||= dimension? ? :key : :count
      end

      def dimension?
        member_type == :dimension
      end

      def measure?
        member_type == :measure
      end

      def fact?
        member_type == :fact
      end

      def to_a
        [member_type,name,attribute_name,order]
      end

      def to_s
        to_a.join("::")
      end

      def self.parse(filter_string,options={})
        new(nil).parse(filter_string,options)
      end

      def parse(filter_string,options={})
        parts = filter_string.split("::")
        @member_type = parts.shift.to_sym
        @name = parts.shift
        @attribute_name = parts.shift
        @order = parts.shift
        self
      end

      [:gt, :lt, :gte, :lte, :ne, :in, :nin, :eq].each do |operator|
        define_method(operator) do |*args|
          filter = MemberFilter.new(self)
          filter.send(operator, *args)
          filter
        end unless method_defined?(operator)
      end 

      [:asc, :desc].each do |sort_dir|
        define_method(sort_dir) do |*args|
          @order = sort_dir
          self
        end unless method_defined?(sort_dir)
      end 

      def to_ary
        nil
      end

      def inspect
        to_s
      end

      def qualified_name
        to_s(:name_only=>true)
      end

      def <=>(other)
        inspect <=> other.inspect
      end

      def ==(other)
        inspect == other.inspect
      end
      alias :eql? :==

      def hash
        inspect.hash
      end

      def method_missing(sym,*args)
        super unless args.length < 1
        @attribute_name = sym
        self
      end

      def validate!(cube)
        valid = if dimension?
          cube.dimensions[name]
        elsif measure?
          cube.measures[name]
        else
          #facts can refer to the current cube or a linked cube
          cube.name.to_s == name.to_s || cube.linked_cubes[name]
        end
        !!valid
      end

    end
  end
end

