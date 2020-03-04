module Grip
  module Exceptions
    class NotFound < Exception
      def initialize(context : HTTP::Server::Context)
        super "404 Not Found"
      end
    end
  end
end
