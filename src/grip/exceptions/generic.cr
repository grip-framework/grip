module Grip
  module Exceptions
    class Generic < Exception
      def initialize(context : HTTP::Server::Context)
        super "Generic exception"
      end
    end
  end
end
