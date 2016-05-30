require "bundler"
require "fluent/test"
require "fluent/plugin/out_chronix"
require "rubygems"
require "rspec"

require_relative "../lib/fluent/plugin/proto/Point.rb"
require_relative "../lib/fluent/plugin/proto/StracePoint.rb"
require_relative "chronix_helper"

class Fluent::ChronixOutput
  attr_reader :solr

  def connectToChronix
    @solr = Mocks::Chronix.new
  end
end
