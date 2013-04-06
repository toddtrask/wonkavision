require "rubygems"
require "active_support"
require "active_support/hash_with_indifferent_access" unless defined?(HashWithIndifferentAccess)
require "active_support/core_ext"
require "active_support/concern"

dir = File.dirname(__FILE__)
[
 "string_formatter",
 "extensions/string",
 "extensions/symbol",
 "extensions/array",
 "extensions/date",
 "analytics",
 "analytics/paginated",
 "analytics/member_filter",
 "analytics/persistence/store",
 "analytics/persistence/store/hash_store",
 "analytics/facts",
 "analytics/aggregation/aggregation_spec",
 "analytics/aggregation/attribute",
 "analytics/aggregation/dimension",
 "analytics/aggregation",
 "analytics/cellset/axis",
 "analytics/cellset/dimension",
 "analytics/cellset/member",
 "analytics/cellset/cell",
 "analytics/cellset/measure",
 "analytics/cellset/calculated_measure",
 "analytics/cellset",
 "analytics/query",
 "analytics/schema.rb",
 "analytics/schema/attribute.rb",
 "analytics/schema/cube.rb",
 "analytics/schema/cube_dimension.rb",
 "analytics/schema/dimension.rb",
 "analytics/schema/measure.rb"
 
].each {|lib|require File.join(dir,'wonkavision',lib)}


module Wonkavision

   NaN = 0.0 / 0.0
  
  class WonkavisionError < StandardError #:nodoc:
  end

end

