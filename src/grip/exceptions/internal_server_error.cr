module Grip
  module Exceptions
    class InternalServerError < Base
      def initialize
        @status = HTTP::Status::INTERNAL_SERVER_ERROR
        super "Please try again later or contact the server administration team."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
