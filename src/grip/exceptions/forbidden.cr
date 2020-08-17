module Grip
  module Exceptions
    class Forbidden < Exception
      def initialize(context : HTTP::Server::Context)
        super "You lack the privilege to access this endpoint."
      end
    end
  end
end
