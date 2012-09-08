require 'treetop'

module EDN
  Treetop.load(File.join(File.dirname(__FILE__), 'grammar.treetop'))

  class Parser
    @@parser = EDNGrammarParser.new
  end
end
