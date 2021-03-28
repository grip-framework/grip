module Grip
  module Exceptions
    abstract class Base < Exception
      getter status : HTTP::Status?

      def status_code : Int32
        @status.not_nil!.value
      end
    end
  end
end
