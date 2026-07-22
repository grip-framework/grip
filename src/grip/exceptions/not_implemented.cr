module Grip
  module Exceptions
    class NotImplemented < Base
      def initialize(message : String? = nil)
        @status_code = HTTP::Status::NOT_IMPLEMENTED
        @message = message if message
        @message = "The requested method is not implemented." unless message
      end
    end
  end
end
