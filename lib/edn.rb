$:.push(File.dirname(__FILE__))
require "edn/version"
require "edn/parser"
require "edn/transform"

module EDN
  @parser = EDN::Parser.new
  @transform = EDN::Transform.new
  @tags = Hash.new

  def self.read(edn)
    @transform.apply(@parser.parse(edn))
  end

  def self.register(tag, func = nil, &block)
    if block_given?
      func = block
    end

    raise "EDN.register requires a block or callable." if func.nil?

    if func.is_a?(Class)
      @tags[tag] = lambda { |*args| func.new(*args) }
    else
      @tags[tag] = func
    end
  end

  def self.unregister(tag)
    @tags[tag] = nil
  end

  def self.tag_value(tag, value)
    func = @tags[tag] || lambda { |data| data }
    func.call(value)
  end
end
