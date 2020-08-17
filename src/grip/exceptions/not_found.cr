module Grip
  module Exceptions
    class NotFound < Exception
      def initialize(context : HTTP::Server::Context)
        super "The endpoint you have requested was not found on the server."
      end
    end
  end
end
