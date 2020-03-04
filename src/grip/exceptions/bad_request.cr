module Grip
  module Exceptions
    class BadRequest < Exception
      def initialize(context : HTTP::Server::Context)
        super "400 Bad Request"
      end
    end
  end
end
