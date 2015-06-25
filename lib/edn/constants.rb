require 'stringio'
require 'set'


module EDN

  # Object returned when there is nothing to return

  NOTHING = Object.new

  # Object to return when we hit end of file. Cant be nil or :eof
  # because either of those could be something in the EDN data.

  EOF = Object.new

  # Chars that are OK inside a symbol.

  SYMBOL_INTERIOR_CHARS =
    Set.new(%w{. # * ! - _ + ? $ % & = < > :} + ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a)

  # Name says it all.

  DIGITS = Set.new(('0'..'9').to_a)
end
