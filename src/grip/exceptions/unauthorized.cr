module Grip
  module Exceptions
    class Unauthorized < Base
      def initialize
        @status_code = HTTP::Status::UNAUTHORIZED
        super "You are not authorized to access this endpoint."
      end
    end
  end
end
