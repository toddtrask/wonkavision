# encoding: UTF-8
require File.expand_path('../lib/wonkavision/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'wonkavision'
  s.homepage = 'http://github.com/sunfishtech/wonkavision'
  s.summary = 'Pseudo-OLAP Querying'
  s.require_path = 'lib'
  s.authors = ['Nathan Stults']
  s.email = ['nathan@sunfish.io']
  s.version = Wonkavision::VERSION
  s.platform = Gem::Platform::RUBY
  s.files = Dir.glob("{lib,test}/**/*") + %w[README.md LICENSE.txt]

  s.add_dependency 'activesupport', '3.2'
  s.add_dependency 'i18n'
 
end

