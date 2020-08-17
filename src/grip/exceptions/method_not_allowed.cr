module Grip
  module Exceptions
    class MethodNotAllowed < Exception
      def initialize(context : HTTP::Server::Context)
        super "Please provide a proper request to the endpoint."
      end
    end
  end
end
