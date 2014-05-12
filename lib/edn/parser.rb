require 'pry'
require 'stringio'
require 'set'


module EDN
  @handlers = {}

  def self.register(tag, func = nil, &block)
    if block_given?
      func = block
    end

    if func.nil?
      func = lambda { |x| x }
    end

    if func.is_a?(Class)
      @tags[tag] = lambda { |*args| func.new(*args) }
    else
      @tags[tag] = func
    end
  end

  def self.unregister(tag)
    @tags[tag] = nil
  end

  def self.tagged_element(tag, element)
    func = @tags[tag]
    if func
      func.call(element)
    else
      EDN::Type::Unknown.new(tag, element)
    end
  end


  class Parser
    SYMBOL_INTERIOR_CHARS = Set.new(%w{. # * ! - _ + ? $ % & = < > :} + ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a)
    DIGITS = Set.new(('0'..'9').to_a)

    READERS = {}

    SYMBOL_INTERIOR_CHARS.each {|n| READERS[n.to_s] = :read_symbol}

    READERS['{'] = :read_map
    READERS['['] = :read_vector
    READERS['('] = :read_list
    READERS['\\'] = :read_char
    READERS['"'] = :read_string
    READERS['.'] = :read_number_or_symbol
    READERS['+'] = :read_number_or_symbol
    READERS['-'] = :read_number_or_symbol
    READERS['/'] = :read_slash
    READERS[':'] = :read_keyword
    READERS['#'] = :read_extension
    DIGITS.each {|n| READERS[n.to_s] = :read_number}

    READERS.default = :unknown

    NOTHING = Object.new

    def initialize(source=$stdin)
      io = source.instance_of?(String) ? StringIO.new(source) : source
      @s = CharStream.new(io)
    end
  
    def eof?
      @s.eof?
    end

    def unknown
      raise "Don't know what to do with #{@s.current} #{@s.current.class}"
    end

    def read_char
      @s.advance
      result = @s.current
      @s.advance
      until @s.eof?
        break unless @s.digit? || @s.alpha?
        result += @s.current
        @s.advance
      end

      return result if result.size == 1

      case result
      when 'newline'
        "\n"
      when 'return'
        "\r"
      when 'tab'
        "\t"
      when 'space'
        " "
      else
        binding.pry
        raise "Unknown char #{result}"
      end
    end

    def read_slash
      @s.advance
      Type::Symbol.new('/')
    end

    def read_number_or_symbol
      leading = @s.current
      @s.advance
      return read_number(leading) if @s.digit?
      read_symbol(leading)
    end

    def read_symbol_chars
      result = ''

      ch = @s.current
      while SYMBOL_INTERIOR_CHARS.include?(ch)
        result << ch
        ch = @s.advance
      end
      return result unless skip_past('/')

      result << '/'
      ch = @s.current
      while SYMBOL_INTERIOR_CHARS.include?(ch)
        result << ch
        ch = @s.advance
      end

      result
    end

    def read_extension
      @s.advance
      #puts "read extension, current: #{@s.current}"
      if @s.current == '{'
        @s.advance
        read_collection(Set, '}')
      elsif @s.current == "_"
        @s.advance
        x = read
        NOTHING
      else
        tag = read_symbol_chars
        #puts "tag: #{tag}"
        value = read
        EDN.tagged_element(tag, value)
      end
    end

    def read_symbol(leading='')
      token = leading + read_symbol_chars
      return true if token == "true"
      return false if token == "false"
      return nil if token == "nil"
      Type::Symbol.new(token)
    end

    def read_keyword
      @s.advance
      read_symbol_chars.to_sym
    end

    def escape_char(ch)
      return '\\' if ch == '\\'
      return "\n" if ch == 'n'
      return "\t" if ch == 't'
      return "\r" if ch == 'r'
      ch
    end

    def read_string
      @s.advance

      result = ''
      until @s.current == '"'
        raise "Unexpected eof" if @s.eof?
        if @s.current == '\\'
          @s.advance
          result << escape_char(@s.current)
        else
          result << @s.current
        end
        @s.advance
      end
      @s.advance
      result
    end
  
    def read
      meta = read_meta
      value = read_basic
      if meta
        value.extend EDN::Metadata
        value.metadata = meta
      end
      value
    end

    def parse
      read
    end

    def read_basic
      @s.skip_ws
      ch = @s.current
      #puts "read_basic: #{ch} #{READERS[ch]}"
      result = self.send(READERS[ch])
      while result == NOTHING
        @s.skip_ws
        result = self.send(READERS[@s.current])
      end
      result
    end
  
    def read_digits
      result = ''

      if @s.current == '+' || @s.current == '-'
        result << @s.current
        @s.advance
      end
 
      while @s.current =~ /[0-9]/
        result << @s.current
        @s.advance
      end

      result
    end

    def skip_past(expected, error_message=nil)
      if @s.current == expected
        @s.advance
        return expected
      elsif error_message
        raise error_message
      end
      nil
    end

    def finish_float(whole_part)
      result = whole_part
      result += skip_past('.', 'Expected .')
      result += read_digits # TBD should be at least 1 digit
      if @s.current == 'e' || @s.current == 'E'
        @s.advance
        result = result + 'e' + read_digits
      end
      result.to_f # TBD deal with 1.0E25
    end

    def read_number(leading='')
      result = leading + read_digits

      if @s.current == '.'
        return finish_float(result)
      elsif skip_past('M') || skip_past('N')
        result.to_i
      else
        result.to_i
      end
    end

    def read_meta
      raw_metadata = []
      @s.skip_ws
      while @s.current == '^'
        @s.advance
        raw_metadata << read_basic
        @s.skip_ws
      end

      metadata = raw_metadata.reverse.reduce({}) do |acc, m|
        case m
        when Symbol then acc.merge(m => true)
        when EDN::Type::Symbol then acc.merge(:tag => m)
        else acc.merge(m)
        end
      end
      metadata.empty? ? nil : metadata
    end

    def read_list
      @s.advance
      read_collection(Array, ')')
    end

    def read_vector
      @s.advance
      read_collection(Array, ']')
    end

    def read_map
      @s.advance
      array = read_collection(Array, '}')
      binding.pry unless array.count.even?
      raise "Need an even number of items for a map" unless array.count.even?
      Hash[*array]
    end

    def read_collection(clazz, closing)
      result = clazz.new

      @s.skip_ws

      ch = @s.current
      while ch != closing
        raise "Unexpected eof" if ch == :eof
        result << read
        @s.skip_ws
        ch = @s.current
      end
      @s.advance
      result
    end
  end
end
