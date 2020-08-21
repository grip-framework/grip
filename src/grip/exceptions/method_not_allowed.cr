module Grip
  module Exceptions
    class MethodNotAllowed < Exception
      def initialize(context : HTTP::Server::Context)
        @status = HTTP::Status::METHOD_NOT_ALLOWED
        super "Please provide a proper request to the endpoint."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
