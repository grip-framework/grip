module Grip
  module Handlers
    class Exception
      include HTTP::Handler

      INSTANCE = new

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex
        if ex.is_a?(Grip::Exceptions::Base)
          call_exception_with_status_code(context, ex, ex.status_code)
        else
          STDOUT.print("\n#{ex.inspect_with_backtrace}")
          STDOUT.flush

          return call_exception_with_status_code(context, ex, context.response.status_code) if Grip.config.error_handlers.has_key?(context.response.status_code)

          context.response.status_code = 500

          context.response.print(
            Grip::ExceptionPage.for_runtime_exception(context, ex).to_s
          ) if Grip.config.env == "development"

          context
        end
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
