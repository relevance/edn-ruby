module EDN
  class Reader < Parser
    include Enumerable

    def each
      #reset!
      return enum_for(:select) unless block_given?

      until eof?
        yield read
      end
    end
  end
end
