module Grip
  module Handlers
    class Exception
      include HTTP::Handler

      INSTANCE = new

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex : Grip::Exceptions::BadRequest
        call_exception_with_status_code(context, ex, 400)
      rescue ex : Grip::Exceptions::Unauthorized
        call_exception_with_status_code(context, ex, 401)
      rescue ex : Grip::Exceptions::Forbidden
        call_exception_with_status_code(context, ex, 403)
      rescue ex : Grip::Exceptions::NotFound
        call_exception_with_status_code(context, ex, 404)
      rescue ex : Grip::Exceptions::MethodNotAllowed
        call_exception_with_status_code(context, ex, 405)
      rescue ex : Grip::Exceptions::InternalServerError
        call_exception_with_status_code(context, ex, 500)
      rescue ex : ::Exception
        STDOUT.print("\n#{ex.inspect_with_backtrace}\n")
        STDOUT.flush

        return call_exception_with_status_code(context, ex, context.response.status_code) if Grip.config.error_handlers.has_key?(context.response.status_code)

        context.response.status_code = 500
        context.response.print("<pre>#{ex.inspect_with_backtrace}\n</pre>") if Grip.config.env == "development"

        context
      end

      private def call_exception_with_status_code(context : HTTP::Server::Context, exception : ::Exception, status_code : Int32)
        return if context.response.closed?
        if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(status_code)
          context.response.status_code = status_code
          context.exception = exception

          Grip.config.error_handlers[status_code].call(context)
        else
          context.response.content_type = "text/html" unless context.response.headers.has_key?("Content-Type")
          context.response.status_code = status_code
          context.response.print(exception.message)

          context
        end
      end
    end
  end
end
