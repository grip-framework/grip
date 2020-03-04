module Grip
  module Exceptions
    class Forbidden < Exception
      def initialize(context : HTTP::Server::Context)
        super "403 Forbidden"
      end
    end
  end
end
