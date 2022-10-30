module Grip
  module Exceptions
    class InternalServerError < Base
      def initialize
        @status_code = HTTP::Status::INTERNAL_SERVER_ERROR
        super "Please try again later or contact the server administration team."
      end
    end
  end
end
