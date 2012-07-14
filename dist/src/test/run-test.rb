#!/usr/bin/env ruby

base_dir = File.expand_path(File.dirname(__FILE__))
top_dir = File.expand_path("..", base_dir)
$LOAD_PATH.unshift(File.join(top_dir, "lib"))
$LOAD_PATH.unshift(File.join(top_dir, "test"))

require "rubygems"
require "bundler"
Bundler.require(:default, :test)

require "helper.rb"
require "lambda_lifter"
test_file = "./test/test_*.rb"
Dir.glob(test_file) do |file|
  require file
end
