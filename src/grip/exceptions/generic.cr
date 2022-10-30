module Grip
  module Exceptions
    class Generic < Base
      def initialize(@status : HTTP::Status)
        @status_code = HTTP::Status::SERVICE_UNAVAILABLE
        super "Something went wrong, please try again."
      end
    end
  end
end
