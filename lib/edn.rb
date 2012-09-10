$:.push(File.dirname(__FILE__))
require "edn/version"
require "edn/parser"
require "edn/transform"

module EDN
  @parser = EDN::Parser.new
  @transform = EDN::Transform.new

  def self.read(edn)
    @transform.apply(@parser.parse(edn))
  end
end
