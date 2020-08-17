module Grip
  module Exceptions
    class InternalServerError < Exception
      def initialize(context : HTTP::Server::Context)
        super "Please try again later or contact the server administration team."
      end
    end
  end
end
