require 'stringio'
require 'set'

puts __FILE__

module EDN
  def self.resolve_metadata(raw_metadata)
    metadata = raw_metadata.reverse.reduce({}) do |acc, m|
      case m
      when Symbol then acc.merge(m => true)
      when EDN::Type::Symbol then acc.merge(:tag => m)
      else acc.merge(m)
      end
    end
    metadata.empty? ? nil : metadata
  end
end
