require 'pry'
require 'stringio'
require 'set'


module EDN
  class CharStream
    def initialize(io=$stdin)
      @io = io
      @current = nil
    end

    def current
      return @current if @current
      advance
    end

    def advance
      return @current if @current == :eof
      @current = @io.getc || :eof
    end

    def digit?(c=current)
      /[0-9]/ =~ c
    end

    def eof?(c=current)
      c == :eof
    end

    def ws?(c=current)
      /[ \t\n,]/ =~ c
    end

    def newline(c=current)
      /[\n\r]/ =~ c
    end

    def repeat(pattern, min=0)
      pos = #io.pos
      result = nil
      while current =~ pattern
        result = result || ''
        result << current
        advance
      end
    end

    def skip_to_eol
      until current == :eof || newline?
        advance
      end
    end

    def skip_ws
      while current != :eof
        if ws?(current)
          advance
        elsif current == ';'
          skip_to_eol
        else
          break
        end
      end
    end
  end
  
  
  class Parser
  
    SYMBOL_INTERIOR_CHARS = Set.new(%w{* ! - _ ? $ % & = < >} + ('a'..'z').to_a + ('A'..'Z').to_a)
    DIGITS = Set.new(('0'..'9').to_a)

    READERS = {
      '{' => :read_map,
      '[' => :read_vector,
      '(' => :read_list,
      '\\' => :read_char,
      '"' => :read_string,
      '.' => :read_number_or_symbol,
      '+' => :read_number_or_symbol,
      '-' => :read_number_or_symbol,
      '#' => :read_extension,
      ':' => :read_keyword
    }

    DIGITS.each {|n| READERS[n.to_s] = :read_number}
    SYMBOL_INTERIOR_CHARS.each {|n| READERS[n.to_s] = :read_symbol}

    READERS.default = :unknown

    def initialize(source=$stdin)
      io = source.instance_of?(String) ? StringIO.new(source) : source
      @s = CharStream.new(io)
    end
  
    def unknown
      raise "Don't know what to do with #{@s.current}"
    end

    def read_char
      @s.advance
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
      if @s.current == '{'
        @s.advance
        read_collection(Set, '}')
      elsif @s.current == "_"
        read
      else
        raise "Dont know what to do with ##{@s.current}"
      end
    end

    def read_symbol
      token = read_symbol_chars
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
      return "\n" if ch == 'n'
      return "\t" if ch == 't'
      "\\#{ch}"
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
      self.send(READERS[ch])
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
      result.to_f # TBD deal with 1.0E25
    end

    def read_number
      result = read_digits

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
=begin
parser = EDN::Parser.new('33')
p parser.read
parser = EDN::Parser.new('abc')
p parser.read
parser = EDN::Parser.new(':abc')
p parser.read
=end
