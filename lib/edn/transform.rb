require 'edn/string_transformer'
require 'edn/types'
require 'bigdecimal'

module EDN
  class Transform < Parslet::Transform
    rule(:true => simple(:x)) { true }
    rule(:false => simple(:x)) { false }
    rule(:nil => simple(:x)) { nil }

    rule(:integer => simple(:num), :precision => simple(:n)) {
      Integer(num)
    }
    rule(:float => simple(:num), :precision => simple(:n)) {
      if n
        BigDecimal(num)
      else
        Float(num)
      end
    }

    rule(:string => simple(:x)) { EDN::StringTransformer.parse_string(x) }
    rule(:keyword => simple(:x)) { x.to_sym }
    rule(:symbol => simple(:x)) { EDN::Type::Symbol.new(x) }
    rule(:character => simple(:x)) {
      case x
      when "newline" then "\n"
      when "tab" then "\t"
      when "space" then " "
      else x.to_s
      end
    }

    rule(:vector => subtree(:array)) { array }
    rule(:list => subtree(:array)) { EDN::Type::List.new(*array) }
    rule(:set => subtree(:array)) { Set.new(array) }
    rule(:map => subtree(:array)) { Hash[array.map { |hash| [hash[:key], hash[:value]] }] }

    rule(:tagged_value => subtree(:x)) {
      EDN.tag_value(x[:tag].to_s, x[:value])
    }
  end
end
