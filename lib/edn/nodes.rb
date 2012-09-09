module EDN
  module Grammar
    module ValueNode
      def to_data
        value.to_data
      end
    end

    module BaseValueNode
      def to_data
        super.to_data
      end
    end
  end

  class TaggedValueNode < Treetop::Runtime::SyntaxNode; end

  class VectorNode < Treetop::Runtime::SyntaxNode
    def to_data
      values.map(&:to_data)
    end
  end

  class ListNode < Treetop::Runtime::SyntaxNode; end
  class MapNode < Treetop::Runtime::SyntaxNode; end
  class SetNode < Treetop::Runtime::SyntaxNode; end

  class StringNode < Treetop::Runtime::SyntaxNode
    def to_data
      eval text_value
    end
  end

  class RegexpNode < Treetop::Runtime::SyntaxNode; end
  class CharacterNode < Treetop::Runtime::SyntaxNode; end
  class IntegerNode < Treetop::Runtime::SyntaxNode; end
  class FloatNode < Treetop::Runtime::SyntaxNode; end

  class KeywordNode < Treetop::Runtime::SyntaxNode
    def to_data
      keyword.to_sym
    end
  end

  class SymbolNode < Treetop::Runtime::SyntaxNode; end

  class BooleanNode < Treetop::Runtime::SyntaxNode
    def to_data
      text_value == "true"
    end
  end

  class NilNode < Treetop::Runtime::SyntaxNode
    def to_data
      nil
    end
  end
end
