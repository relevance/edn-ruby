require 'parslet'

module EDN
  class Parser < Parslet::Parser
    root(:top)

    rule(:top) {
      space? >> element >> space?
    }

    rule(:element) {
      element_without_metadata |
      (metadata >> space).maybe >> element_without_metadata.as(:element)
    }

    rule(:element_without_metadata) {
      base_element | tagged_element
    }

    rule(:tagged_element) {
      tag >> space >> base_element.as(:element)
    }

    rule(:base_element) {
      vector |
      list |
      set |
      map |
      boolean |
      str('nil').as(:nil) |
      keyword |
      string |
      character |
      float |
      integer |
      symbol
    }

    rule(:metadata) {
      str('^{') >>
      ((keyword | symbol | string).as(:key) >> top.as(:value)).repeat.as(:metadata) >>
      space? >>
      str('}')
    }

    # Collections

    rule(:vector) {
      str('[') >>
      top.repeat.as(:vector) >>
      space? >>
      str(']')
    }

    rule(:list) {
      str('(') >>
      top.repeat.as(:list) >>
      space? >>
      str(')')
    }

    rule(:set) {
      str('#{') >>
      top.repeat.as(:set) >>
      space? >>
      str('}')
    }

    rule(:map) {
      str('{') >>
      (top.as(:key) >> top.as(:value)).repeat.as(:map) >>
      space? >>
      str('}')
    }

    # Primitives

    rule(:integer) {
      (str('-').maybe >>
       (str('0') | match('[1-9]') >> digit.repeat)).as(:integer) >>
      str('N').maybe.as(:precision)
    }

    rule(:float) {
      (str('-').maybe >>
       (str('0') | (match('[1-9]') >> digit.repeat)) >>
       str('.') >> digit.repeat(1) >>
       (match('[eE]') >> match('[\-+]').maybe >> digit.repeat).maybe).as(:float) >>
      str('M').maybe.as(:precision)
    }

    rule(:string) {
      str('"') >>
      (str('\\') >> any | str('"').absent? >> any).repeat.as(:string) >>
      str('"')
    }

    rule(:character) {
      str("\\") >>
      (str('newline') | str('space') | str('tab') |
       match['[:graph:]']).as(:character)
    }

    rule(:keyword) {
      str(':') >> symbol.as(:keyword)
    }

    rule(:symbol) {
      (symbol_chars >> (str('/') >> symbol_chars).maybe |
       str('/')).as(:symbol)
    }

    rule(:boolean) {
      str('true').as(:true) | str('false').as(:false)
    }

    # Parts

    rule(:tag) {
      str('#') >> symbol.as(:tag)
    }

    rule(:symbol_chars) {
      (symbol_first_char >>
       valid_chars.repeat) |
      match['\-\.']
    }

    rule(:symbol_first_char) {
      (match['\-\.'] >> match['0-9'].absent? |
       match['\#\:0-9'].absent?) >> valid_chars
    }

    rule(:valid_chars) {
      match['[:alnum:]'] | sym_punct
    }

    rule(:sym_punct) {
      match['\.\*\+\!\-\?\:\#\_']
    }

    rule(:digit) {
      match['0-9']
    }

    rule(:space) {
      match('[\s,]').repeat(1)
    }

    rule(:space?) { space.maybe }
  end
end
