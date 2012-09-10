module EDN
  module Type
    class Unknown < Struct.new(:tag, :value)
      def to_edn
        "##{tag} #{value.to_edn}"
      end
    end
  end
end
