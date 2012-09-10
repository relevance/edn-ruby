module EDN
  module Type
    class List < ::Array
      def self.new(*values)
        self.[](*values)
      end
    end
  end
end
