module EDN
  module Metadata
    def self.extended(base)
      base.instance_eval do
        alias :to_edn_without_metadata :to_edn
        alias :to_edn :to_edn_with_metadata
      end
    end

    attr_accessor :metadata

    def to_edn_with_metadata
      '^' + metadata.to_edn + ' ' + self.to_edn_without_metadata
    end
  end
end
