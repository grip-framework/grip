module Grip
  module Exceptions
    class MethodNotAllowed < Base
      def initialize
        @status_code = HTTP::Status::METHOD_NOT_ALLOWED
        super "Please provide a proper request to the endpoint."
      end
    end
  end
end
