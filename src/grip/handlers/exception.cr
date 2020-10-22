module Grip
  module Handlers
    # :nodoc:
    class Exception
      include HTTP::Handler

      property handlers : Hash(Int32, Grip::Controllers::Exception)

      def initialize
        @handlers = {} of Int32 => Grip::Controllers::Exception
      end

      def initialize(handlers : Hash(Int32, Grip::Controllers::Exception))
        @handlers = handlers
      end

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex
        context.response.status_code = 500 if !context.response.status_code.in?([400, 401, 403, 404, 405, 500])
        if ex.is_a?(Exceptions::Base)
          context.response.status_code = ex.status_code
          call_exception_with_status_code(context, ex, ex.status_code)
        else
          call_exception_with_status_code(context, ex, context.response.status_code)
        end
      end

      private def call_exception_with_status_code(context : HTTP::Server::Context, exception : ::Exception, status_code : Int32)
        return context if context.response.closed?
        if !@handlers.empty? && @handlers.has_key?(status_code)
          context.response.status_code = status_code
          context.exception = exception

          @handlers[status_code].call(context)
        else
          {% if flag?(:hideAllExceptions) %}
            context.response.print("500 Internal Server Error")
          {% else %}
            context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
            context.response.print(Grip::Minuscule::ExceptionPage.for_runtime_exception(context, exception).to_s)
          {% end %}

          context
        end
      end
    end
  end
end
