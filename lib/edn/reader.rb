module EDN
  class Reader
    include Enumerable

    def initialize(source)
      @parser = Parser.new(source)
    end

    def each
      return enum_for(:select) unless block_given?

      until (result = @parser.read) == EOF
        yield result
      end
    end
  end
end
