module Grip
  module Exceptions
    class NotAcceptable < Base
      def initialize
        @status_code = HTTP::Status::NOT_ACCEPTABLE
        super "Please provide a proper request to the endpoint."
      end
    end
  end
end
