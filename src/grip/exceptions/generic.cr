module Grip
  module Exceptions
    class Generic < Exception
      def initialize(context : HTTP::Server::Context)
        super "Sorry, something went wrong, please try again later."
      end
    end
  end
end
