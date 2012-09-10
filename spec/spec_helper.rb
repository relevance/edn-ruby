require 'rspec'
require 'edn'
require 'parslet/rig/rspec'
require 'parslet/convenience'
require 'rantly'

REPEAT = (ENV["REPEAT"] || 100).to_i

RSpec.configure do |c|
  c.fail_fast = true
end

module RantlyHelpers

  SYMBOL = lambda { |_|
    branch(PLAIN_SYMBOL, NAMESPACED_SYMBOL)
  }

  PLAIN_SYMBOL = lambda { |_|
    sized(range(1, 100)) {
      s = string(/[[:alnum:]]|[\-\.\.\*\+\!\-\?\:\#\_]/)
      guard s =~ /^[A-Za-z\-\.\.\*\+\!\-\?\:\#\_]/
      guard s !~ /^[\-\.][0-9]/
      guard s !~ /^[\:\#]/
      s
    }
  }

  NAMESPACED_SYMBOL = lambda { |_|
    [call(PLAIN_SYMBOL), call(PLAIN_SYMBOL)].join("/")
  }

  INTEGER = lambda { |_| integer.to_s }

  STRING = lambda { |_| sized(range(1, 100)) { string.inspect } }

  FLOAT = lambda { |_| (float * range(-1000, 1000)).to_s }

  FLOAT_WITH_EXP = lambda { |_|
    [float, choose("e", "E", "e+", "E+", "e-", "e+"), positive_integer].
    map(&:to_s).
    join("")
  }

  CHARACTER = lambda { |_|
    "\\" +
    sized(1) {
      freq([1, [:choose, "newline", "space", "tab"]],
           [5, [:string, :graph]])
    }
  }

  BOOL_OR_NIL = lambda { |_|
    choose("true", "false", "nil")
  }

  ARRAY = lambda { |_|
    array(range(0, 10)) { call(VALUE) }
  }

  VECTOR = lambda { |_|
    "[" + call(ARRAY).join(" ") + "]"
  }

  LIST = lambda { |_|
    "(" + call(ARRAY).join(" ") + ")"
  }

  SET = lambda { |_|
    '#{' + call(ARRAY).join(" ") + '}'
  }

  MAP = lambda { |_|
    size = range(0, 10)
    keys = array(size) { call(VALUE) }
    values = array(size) { call(VALUE) }
    arrays = keys.zip(values)
    '{' + arrays.map { |array| array.join(" ") }.join(", ") + '}'
  }

  VALUE = lambda { |_|
    freq([10, BASIC_VALUE],
         [1, TAGGED_VALUE])
  }

  BASIC_VALUE = lambda { |_|
    branch(INTEGER,
           FLOAT,
           FLOAT_WITH_EXP,
           STRING,
           SYMBOL,
           CHARACTER,
           BOOL_OR_NIL,
           VECTOR,
           LIST,
           SET,
           MAP)
  }

  TAGGED_VALUE = lambda { |_|
    "#" + [call(SYMBOL), call(BASIC_VALUE)].join(" ")
  }

  def rant(fun, count = REPEAT)
    Rantly(count) { call(fun) }
  end
end
