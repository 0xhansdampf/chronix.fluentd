# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: Point.proto

require 'protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "Chronix.Point" do
    optional :t, :int64, 1
    optional :v, :double, 2
  end
  add_message "Chronix.Points" do
    repeated :p, :message, 1, "Chronix.Point"
  end
end

module Chronix
  Point = Google::Protobuf::DescriptorPool.generated_pool.lookup("Chronix.Point").msgclass
  Points = Google::Protobuf::DescriptorPool.generated_pool.lookup("Chronix.Points").msgclass
end
