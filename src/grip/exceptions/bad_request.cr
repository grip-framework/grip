module Grip
  module Exceptions
    class BadRequest < Base
      def initialize
        @status_code = HTTP::Status::BAD_REQUEST
        super "Please provide a proper request to the endpoint."
      end
    end
  end
end
