module Grip
  module Handlers
    # :nodoc:
    class Exception
      include HTTP::Handler

      property handlers : Hash(String, HTTP::Handler)

      def initialize(@environment : String)
        @handlers = {} of String => HTTP::Handler
      end

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex
        return context if context.response.closed?

        if ex.is_a?(Grip::Exceptions::Base)
          call_exception(context, ex, ex.status_code.value)
        else
          call_exception(context, ex, context.response.status_code)
        end
      end

      private def call_exception(context : HTTP::Server::Context, exception : ::Exception, status_code : Int32)
        return context if context.response.closed?

        if @handlers.has_key?(exception.class.name)
          context.response.status_code = status_code
          context.exception = exception

          context.response.close
          @handlers[exception.class.name].call(context)
        else
          if status_code.in?(400..599)
            context.response.status_code = status_code
          else
            context.response.status_code = 500
          end

          context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})

          if @environment == "production"
            context.response.print("An error occured, please try again later.")
          else
            context.response.print(Grip::Minuscule::ExceptionPage.for_runtime_exception(context, exception).to_s)
          end

          context.response.close
          context
        end
      end
    end
  end
end
