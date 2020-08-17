module Grip
  module Exceptions
    class Unauthorized < Exception
      def initialize(context : HTTP::Server::Context)
        super "You are not authorized to access this endpoint."
      end
    end
  end
end
