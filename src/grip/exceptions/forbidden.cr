module Grip
  module Exceptions
    class Forbidden < Base
      def initialize
        @status = HTTP::Status::FORBIDDEN
        super "You lack the privilege to access this endpoint."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
