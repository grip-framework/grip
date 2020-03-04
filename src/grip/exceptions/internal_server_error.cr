module Grip
  module Exceptions
    class InternalServerError < Exception
      def initialize(context : HTTP::Server::Context)
        super "500 Internal Server Error"
      end
    end
  end
end
