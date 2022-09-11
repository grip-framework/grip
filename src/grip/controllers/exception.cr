module Grip
  module Controllers
    class Exception
      alias Context = HTTP::Server::Context

      include HTTP::Handler
      include Helpers::Singleton

      def call(context : Context) : Context
        context.html(context.exception)
      end
    end
  end
end
