require 'rspec'
require 'edn'
require 'parslet/rig/rspec'
require 'parslet/convenience'
require 'rantly'

REPEAT = (ENV["REPEAT"] || 100).to_i

RSpec.configure do |c|
  c.fail_fast = true
  c.filter_run_including :focused => true
  c.alias_example_to :fit, :focused => true
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.run_all_when_everything_filtered = true
end

module RantlyHelpers

  KEYWORD = lambda { |_|
    call(SYMBOL).to_sym.to_edn
  }

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

  INTEGER = lambda { |_| integer.to_edn }

  STRING = lambda { |_| sized(range(1, 100)) { string.to_edn } }

  FLOAT = lambda { |_| (float * range(-1000, 1000)).to_edn }

  FLOAT_WITH_EXP = lambda { |_|
    # limited range because of Infinity
    f = float.to_s
    guard f !~ /[Ee]/

    [f, choose("e", "E", "e+", "E+", "e-", "e+"), range(1, 100)].
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
    call(ARRAY).to_edn
  }

  LIST = lambda { |_|
    EDN::Type::List.new(*call(ARRAY)).to_edn
  }

  SET = lambda { |_|
    Set.new(call(ARRAY)).to_edn
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
         [1, INST],
         [1, TAGGED_VALUE])
  }

  BASIC_VALUE = lambda { |_|
    branch(INTEGER,
           FLOAT,
           FLOAT_WITH_EXP,
           STRING,
           KEYWORD,
           SYMBOL,
           CHARACTER,
           BOOL_OR_NIL,
           VECTOR,
           LIST,
           SET,
           MAP)
  }

  TAG = lambda { |_|
    tag = call(SYMBOL)
    guard tag =~ /^[A-Za-z]/
    "##{tag}"
  }

  TAGGED_VALUE = lambda { |_|
    [call(TAG), call(BASIC_VALUE)].join(" ")
  }

  INST = lambda { |_|
    DateTime.new(range(0, 2500), range(1, 12), range(1, 28), range(0, 23), range(0, 59), range(0, 59), "#{range(-12,12)}").to_edn
  }

  def rant(fun, count = REPEAT)
    Rantly(count) { call(fun) }
  end
end
