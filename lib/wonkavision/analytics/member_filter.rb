module Wonkavision
  module Analytics
    class MemberFilter
      extend Forwardable

      attr_reader :operator, :member_reference
      attr_accessor :value

      def initialize(member_name_or_reference, options={})
        @member_reference = member_name_or_reference.kind_of?(MemberReference) ? 
          member_name_or_reference : MemberReference.new(member_name_or_reference, options)

        @operator = options[:operator] || options[:op] || :eq
        @value = options[:value]
      end

      def_delegators :@member_reference, :member_type, :name, :attribute_name, :dimension?, :measure?,:fact?,
                                         :method_missing, :validate!

      def delimited_value(for_eval=false)
        case value
        when nil then "nil"
        when String, Symbol then "'#{value}'"
        when Time then for_eval ? "Time.parse('#{value}')" : "time(#{value})"
        else value.inspect
        end
      end


      def to_s(options={})
        properties = [member_type,name,attribute_name,operator,delimited_value]
        properties.pop if options[:exclude_value] || options[:name_only]
        properties.pop if options[:name_only]
        properties.join("::")
      end

      def self.parse(filter_string,options={})
        new(nil).parse(filter_string,options)
      end

      def parse(filter_string,options={})
        @member_reference = MemberReference.parse(filter_string)
        parts = filter_string.split("::")[3..-1]
        @operator = parts.shift.to_sym
        @value = parse_value(options[:value] || parts.shift || @value)
        self
      end

     [:gt, :lt, :gte, :lte, :ne, :in, :nin, :eq].each do |operator|
        define_method(operator) do |*args|
          @value = args[0] if args.length > 0
          @operator = operator; self
        end unless method_defined?(operator)
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
    
      private

      def parse_value(value_string)
        case value_string
        when /^(\'|\").*(\'|\")$/ then parse_value(value_string[1..-2])
        when /^time\(.*\)$/ then Time.parse(value_string[5..-2])
        when /^\[.*\]$/ then parse_array(value_string)
        when String then value_string.is_numeric? ? eval(value_string) : value_string
        else value_string
        end
      end

      def parse_array(array_string)
        base = array_string[1..-2]
        parts = base.split(/\s*,\s*/)
        parts.map { |p| parse_value(p) }
      end
  

    end
  end
end
