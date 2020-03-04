module Grip
  module Exceptions
    class MethodNotAllowed < Exception
      def initialize(context : HTTP::Server::Context)
        super "405 Method Not Allowed"
      end
    end
  end
end
