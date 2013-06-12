require "rubygems"
require "active_support"
require "active_support/hash_with_indifferent_access" unless defined?(HashWithIndifferentAccess)
require "active_support/core_ext"
require "active_support/concern"
require "active_record"
require "arel"

dir = File.dirname(__FILE__)
[
 "string_formatter",
 "extensions/string",
 "extensions/symbol",
 "extensions/array",
 "extensions/date",
 "api/helper",
 "analytics",
 "analytics/paginated",
 "analytics/member_reference",
 "analytics/member_filter",
 "analytics/persistence/store",
 "analytics/cellset/axis",
 "analytics/cellset/dimension",
 "analytics/cellset/member",
 "analytics/cellset/cell",
 "analytics/cellset/measure",
 "analytics/cellset",
 "analytics/query",
 "analytics/schema.rb",
 "analytics/schema/attribute.rb",
 "analytics/schema/linked_cube.rb",
 "analytics/schema/cube.rb",
 "analytics/schema/cube_dimension.rb",
 "analytics/schema/dimension.rb",
 "analytics/schema/measure.rb",
 "analytics/persistence/store/active_record_store.rb",
 "analytics/persistence/store/active_record_store/query_builder.rb"
 
 
].each {|lib|require File.join(dir,'wonkavision',lib)}


module Wonkavision

   NaN = 0.0 / 0.0
  
  class WonkavisionError < StandardError #:nodoc:
  end

end

