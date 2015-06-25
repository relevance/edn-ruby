require 'stringio'
require 'set'


module EDN
  TAGS = {}

  def self.register(tag, func = nil, &block)
    if block_given?
      func = block
    end

    if func.nil?
      func = lambda { |x| x }
    end

    if func.is_a?(Class)
      TAGS[tag] = lambda { |*args| func.new(*args) }
    else
      TAGS[tag] = func
    end
  end

  def self.unregister(tag)
    TAGS[tag] = nil
  end

  def self.tagged_element(tag, element)
    func = TAGS[tag]
    if func
      func.call(element)
    else
      EDN::Type::Unknown.new(tag, element)
    end
  end
end
