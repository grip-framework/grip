module Grip
  module Exceptions
    class Generic < Base
      def initialize(@status : HTTP::Status)
        super "Something went wrong, please try again."
      end

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
