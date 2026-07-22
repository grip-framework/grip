module Grip
  module Controllers
    module HTTP
      macro included
        alias Context = ::HTTP::Server::Context

        include ::HTTP::Handler
        include Grip::Helpers::Singleton

        def get(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def head(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def post(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def put(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def delete(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def connect(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def options(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def trace(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def patch(context : Context) : Context
          raise Grip::Exceptions::NotImplemented.new
        end

        def call(context : Context) : Context
          case context.request.method
          when "GET"
            get(context)
          when "HEAD"
            head(context)
          when "POST"
            post(context)
          when "PUT"
            put(context)
          when "DELETE"
            delete(context)
          when "CONNECT"
            connect(context)
          when "OPTIONS"
            options(context)
          when "TRACE"
            trace(context)
          when "PATCH"
            patch(context)
          else
            raise Grip::Exceptions::MethodNotAllowed.new
          end
        end
      end
    end

    alias Http = HTTP
  end
end
