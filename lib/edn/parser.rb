require 'treetop'

module EDN
  class Parser
    Treetop.load(File.join(File.dirname(__FILE__), 'grammar.treetop'))
    @@parser = EDN::GrammarParser.new

    def parse(data)
      # Pass the data over to the parser instance
      tree = @@parser.parse(data)

      # If the AST is nil then there was an error during parsing
      # we need to report a simple error message to help the user.
      if(tree.nil?)
        raise Exception, "Parse error at offset: #{@@parser.index}"
      end

      tree
    end
  end
end
