module Grip
  module Controller
    class Http < Base
      def get(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def post(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def put(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def patch(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def delete(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def options(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def head(context : HTTP::Server::Context)
        context.response.status_code = 405
      end

      def call(context : HTTP::Server::Context)
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
          call_next(context)
        end
      end
    end
  end
end
