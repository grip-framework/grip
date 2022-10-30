module Grip
  module Exceptions
    class NotFound < Base
      def initialize
        @status_code = HTTP::Status::NOT_FOUND
        super "The endpoint you have requested was not found on the server."
      end
    end
  end
end
