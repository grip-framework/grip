module Grip
  module Exceptions
    class BadRequest < Base
      def initialize
        @status = HTTP::Status::BAD_REQUEST
        super "Please provide a proper request to the endpoint."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
