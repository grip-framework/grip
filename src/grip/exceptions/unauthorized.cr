module Grip
  module Exceptions
    class Unauthorized < Base
      def initialize
        @status = HTTP::Status::UNAUTHORIZED
        super "You are not authorized to access this endpoint."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
