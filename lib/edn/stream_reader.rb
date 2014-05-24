module EDN
  class StreamReader

    def initialize(handler)
      @handler   = handler
      @parser    = Parser.new
      @transform = Transform.new
    end

    def <<(s)
      @buffer ||= ''
      @buffer << s

      begin
        consume
      rescue Parslet::ParseFailed => ignored
        # ignore the parsing exceptions
        # the form is incomplete, we'll parse when next chunk arrives
      end
      
      self
    end

    def close
      consume
    end

    def reset
      @buffer = nil
    end

    private

    def consume
      while @buffer
        element, rest = @parser.parse_prefix(@buffer)
        @buffer       = rest
        @handler.call(@transform.apply(element))
      end
    end
  end
end
