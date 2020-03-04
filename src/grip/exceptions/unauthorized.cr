module Grip
  module Exceptions
    class Unauthorized < Exception
      def initialize(context : HTTP::Server::Context)
        super "401 Unauthorized"
      end
    end
  end
end
