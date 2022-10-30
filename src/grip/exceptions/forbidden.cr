module Grip
  module Exceptions
    class Forbidden < Base
      def initialize
        @status_code = HTTP::Status::FORBIDDEN
        super "You lack the privilege to access this endpoint."
      end
    end
  end
end
