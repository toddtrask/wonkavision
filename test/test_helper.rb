$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rubygems"
require 'bundler'
Bundler.setup

require 'minitest/autorun'
require 'minitest/should'
require "mocha/mini_test"


dir = File.dirname(__FILE__)
require File.join(dir,"..","lib","wonkavision")

$test_dir = dir

Wonkavision::Analytics::Persistence::ActiveRecordStore.connect(
  :adapter => "sqlite3",
  :database  => "#{$test_dir}/db"
)
    
class StatStore < Wonkavision::Analytics::Persistence::Store
  attr_reader :data, :query
    
  def initialize(data)
    @data = data
  end
  def execute_query(query, &block)
    @query = query
    if block_given?
      @data.each do |record|
        yield record
      end
    else
      @data
    end
  end

  def each(query, &block)
    @query = query
    @data.each do |record|
      yield record
    end
  end
end

class WonkavisionTest < Minitest::Should::TestCase
end