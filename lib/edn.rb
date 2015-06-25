$:.push(File.dirname(__FILE__))
require 'edn/version'
require 'edn/constants'
require 'edn/tags'
require 'edn/core_ext'
require 'edn/types'
require 'edn/metadata'
require 'edn/char_stream'
require 'edn/parser'
require 'edn/reader'

module EDN
  def self.read(edn, eof_value=NOTHING)
    EDN::Reader.new(edn).read(eof_value)
  end

  def self.tagout(tag, element)
    ["##{tag}", element.to_edn].join(" ")
  end

  def self.symbol(text)
    EDN::Type::Symbol.new(text)
  end

  def self.list(*values)
    EDN::Type::List.new(*values)
  end
end

EDN.register("inst") do |value|
  DateTime.parse(value)
end

EDN.register("uuid") do |value|
  EDN::Type::UUID.new(value)
end
