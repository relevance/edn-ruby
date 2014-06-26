require 'stringio'
require 'set'


module EDN

  # Object returned when there is nothing to return

  NOTHING = Object.new

  # Object to return when we hit end of file. Cant be nil or :eof
  # because either of those could be something in the EDN data.

  EOF = Object.new

  # Reader table

  READERS = {}
  SYMBOL_INTERIOR_CHARS =
    Set.new(%w{. # * ! - _ + ? $ % & = < > :} + ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a)

  SYMBOL_INTERIOR_CHARS.each {|n| READERS[n.to_s] = :read_symbol}

  DIGITS = Set.new(('0'..'9').to_a)

  DIGITS.each {|n| READERS[n.to_s] = :read_number}

  READERS.default = :unknown

  READERS['{'] = :read_map
  READERS['['] = :read_vector
  READERS['('] = :read_list
  READERS['\\'] = :read_char
  READERS['"'] = :read_string
  READERS['.'] = :read_number_or_symbol
  READERS['+'] = :read_number_or_symbol
  READERS['-'] = :read_number_or_symbol
  READERS[''] = :read_number_or_symbol
  READERS['/'] = :read_slash
  READERS[':'] = :read_keyword
  READERS['#'] = :read_extension
  READERS[:eof] = :read_eof

  def self.register_reader(ch, handler=nil, &block)
    if handler
      READERS[ch] = handler
    else
      READERS[ch] = block
    end
  end

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

  class Parser
    def initialize(source, *extra)
      io = source.instance_of?(String) ? StringIO.new(source) : source
      @s = CharStream.new(io)
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

    def eof?
      @s.eof?
    end

    def unknown
      raise "Don't know what to do with #{@s.current} #{@s.current.class}"
    end

    def read_eof
      EOF
    end

    def read_char
      result = @s.advance
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
      return result unless @s.skip_past('/')

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
      if @s.current == '{'
        @s.advance
        read_collection(Set, '}')
      elsif @s.current == "_"
        @s.advance
        x = read
        NOTHING
      else
        tag = read_symbol_chars
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

    def call_reader(reader)
      if reader.instance_of? Symbol
        self.send(reader)
      else
        self.instance_exec(&reader)
      end
    end

    def read_basic
      @s.skip_ws
      ch = @s.current
      result = call_reader(READERS[ch])
      while NOTHING.equal?(result)
        @s.skip_ws
        result = call_reader(READERS[@s.current])
      end
      result
    end
  
    def read_digits(min_digits=0)
      result = ''

      if @s.current == '+' || @s.current == '-'
        result << @s.current
        @s.advance
      end
 
      n_digits = 0
      while @s.current =~ /[0-9]/
        n_digits += 1
        result << @s.current
        @s.advance
      end

      raise "Expected at least #{min_digits} digits, found #{result}" unless n_digits >= min_digits
      result
    end

    def finish_float(whole_part)
      result = whole_part
      result += @s.skip_past('.', 'Expected .')
      result += read_digits(1)
      if @s.current == 'e' || @s.current == 'E'
        @s.advance
        result = result + 'e' + read_digits
      end
      result.to_f 
    end

    def read_number(leading='')
      result = leading + read_digits

      if @s.current == '.'
        return finish_float(result)
      elsif @s.skip_past('M') || @s.skip_past('N')
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
      read_collection(EDN::Type::List, ')')
    end

    def read_vector
      @s.advance
      read_collection(Array, ']')
    end

    def read_map
      @s.advance
      array = read_collection(Array, '}')
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
