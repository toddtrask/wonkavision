# encoding: UTF-8
# This concept is torn from the chest cavity of
# jnunemakers plucky library (https://github.com/jnunemaker/plucky/blob/master/lib/plucky/extensions/symbol.rb)
module Wonkavision
  module Extensions
    module Symbol

      [:key, :caption, :sort].each do |dimension_attribute|
        define_method(dimension_attribute) do
          _member_reference(dimension_attribute, :member_type=>:dimension)
        end unless method_defined?(dimension_attribute)
      end

      [:sum, :count, :min, :max, :avg].each do |measure_attribute|
        define_method(measure_attribute) do
          _member_reference(measure_attribute, :member_type=>:measure)
        end unless method_defined?(measure_attribute)
      end

      def method_missing(name,*args)
        _member_reference(name) if _is_member_reference?
      end

      private
      def _member_type
        case self
        when :measures then :measure
        when :facts then :fact
        else :dimension
        end
      end

      def _is_member_reference?
        [:dimensions,:measures,:facts].include?(self)
      end

       def _member_reference(name, options={})
        options[:member_type] ||= _member_type
        if !_is_member_reference?
          member_name = self
          options[:attribute_name] = name
        else
          member_name = name
        end
        Wonkavision::Analytics::MemberReference.new(member_name,options)
      end

    end
  end
end


class Symbol
  include Wonkavision::Extensions::Symbol
end
