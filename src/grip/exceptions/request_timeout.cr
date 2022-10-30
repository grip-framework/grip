module Grip
  module Exceptions
    class RequestTimeout < Base
      def initialize
        @status_code = HTTP::Status::REQUEST_TIMEOUT
        super "Your request to the endpoint has timed out."
      end
    end
  end
end
