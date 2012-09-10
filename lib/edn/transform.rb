require 'edn/string_transformer'
require 'edn/types'

module EDN
  class Transform < Parslet::Transform
    rule(:true => simple(:x)) { true }
    rule(:false => simple(:x)) { false }
    rule(:nil => simple(:x)) { nil }

    rule(:integer => simple(:x)) { Integer(x) }
    rule(:float => simple(:x)) { Float(x) }

    rule(:string => simple(:x)) { EDN::StringTransformer.parse_string(x) }
    rule(:regexp => simple(:x)) { Regexp.new(x) }
    rule(:keyword => simple(:x)) { x.to_sym }
    rule(:symbol => simple(:x)) { EDN::Type::Symbol.new(x) }
    rule(:character => simple(:x)) {
      case x
      when "newline" then "\n"
      when "tab" then "\t"
      when "space" then " "
      else x
      end
    }

    rule(:vector => subtree(:array)) { array }
    rule(:list => subtree(:array)) { EDN::Type::List.new(*array) }
    rule(:set => subtree(:array)) { Set.new(array) }
    rule(:map => subtree(:array)) { Hash[array.map { |hash| [hash[:key], hash[:value]] }] }

    rule(:tag => simple(:x)) { x.to_sym }
    rule(:tagged_value => subtree(:x)) {
      EDN.tag_value(x[:tag], x[:value])
    }
  end
end
