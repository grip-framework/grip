module Grip
  module Handlers
    class Exception < Base
      alias ExceptionHandler = ::HTTP::Handler

      # Pre-allocated header for default error response
      CONTENT_TYPE_HTML = {"Content-Type" => "text/html; charset=UTF-8"}

      property handlers : Hash(String, ExceptionHandler)

      def initialize
        @handlers = Hash(String, ExceptionHandler).new
      end

      def add_route(
        verb : String,
        path : String,
        handler : ExceptionHandler,
        via : Symbol | Array(Symbol) | Nil = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      @[AlwaysInline]
      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        call_next(context) || context
      rescue ex : ::Exception
        return context if context.response.closed?
        handle_exception(context, ex)
      end

      @[AlwaysInline]
      private def handle_exception(context : ::HTTP::Server::Context, exception : ::Exception) : ::HTTP::Server::Context
        return context if context.response.closed?

        status_code = if exception.is_a?(Grip::Exceptions::Base)
                        exception.status_code.value
                      else
                        context.response.status_code
                      end

        if handler = @handlers[exception.class.name]?
          execute_custom_handler(context, handler, exception, status_code)
        else
          render_default_error(context, exception, status_code)
        end
      end

      @[AlwaysInline]
      private def execute_custom_handler(
        context : ::HTTP::Server::Context,
        handler : ExceptionHandler,
        exception : ::Exception,
        status_code : Int32
      ) : ::HTTP::Server::Context
        context.response.status_code = status_code
        context.exception = exception

        handler.call(context)
        context.response.close
        context
      end

      @[AlwaysInline]
      private def render_default_error(
        context : ::HTTP::Server::Context,
        exception : ::Exception,
        status_code : Int32
      ) : ::HTTP::Server::Context
        response = context.response

        # Clamp status code to valid error range
        response.status_code = status_code.clamp(400, 599)
        response.headers.merge!(CONTENT_TYPE_HTML)
        response.print(Grip::Minuscule::ExceptionPage.new(context, exception))
        response.close

        context
      rescue exception : IO::Error
        context
      end
    end
  end
end
