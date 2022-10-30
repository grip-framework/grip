module Grip
  module Exceptions
    class PayloadTooLarge < Base
      def initialize
        @status_code = HTTP::Status::PAYLOAD_TOO_LARGE
        super "Your request to the endpoint has been denied, please provide a proper payload."
      end
    end
  end
end
