module Grip
  module Exceptions
    class Unauthorized < Exception
      def initialize(context : HTTP::Server::Context)
        @status = HTTP::Status::UNAUTHORIZED
        super "You are not authorized to access this endpoint."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
