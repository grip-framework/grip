module Grip
  module Extensions
    module NamedTuple
      def valid?(key : Symbol)
        result = yield self.[key]

        unless result
          raise "Validation of #{key} failed, please make sure you provide a proper value."
        end

        self
      end
    end
  end
end
