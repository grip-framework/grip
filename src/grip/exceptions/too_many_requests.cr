module Grip
  module Exceptions
    class TooManyRequests < Base
      def initialize
        @status_code = HTTP::Status::TOO_MANY_REQUESTS
        super "Your request to the endpoint has been limited, please try again later."
      end
    end
  end
end
