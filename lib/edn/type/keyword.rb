module EDN
  module Type
    class Keyword
      attr_reader :keyword

      def initialize(keyword)
        @keyword = keyword
      end

      def ==(other)
        return false unless other.is_a?(Keyword)
        keyword == other.keyword
      end
      alias :eql? :==

      def to_s
        keyword.to_s
      end

      def to_edn
        ":#{to_s}"
      end
    end
  end
end
