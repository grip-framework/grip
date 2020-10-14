module Grip
  module Controllers
    class Http < Base
      def get(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def post(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def put(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def patch(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def delete(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def options(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def head(context : HTTP::Server::Context) : HTTP::Server::Context
        context
          .halt
      end

      def call(context : HTTP::Server::Context) : HTTP::Server::Context
        case context.request.method
        when "GET"
          get(context)
        when "POST"
          post(context)
        when "PUT"
          put(context)
        when "PATCH"
          patch(context)
        when "DELETE"
          delete(context)
        when "OPTIONS"
          options(context)
        when "HEAD"
          head(context)
        else
          raise Exceptions::MethodNotAllowed.new
        end
      end
    end
  end
end
