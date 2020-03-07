module Grip
  module Core
    class Init
      include HTTP::Handler

      INSTANCE = new

      def call(context : HTTP::Server::Context)
        context.response.content_type = "text/html" unless context.response.headers.has_key?("Content-Type")
        call_next context
      end
    end
  end
end
