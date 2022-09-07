module Grip
  module Handlers
    # :nodoc:
    class Exception
      include HTTP::Handler

      property handlers : Hash(String, Grip::Controllers::Base)

      def initialize(@environment : String)
        @handlers = {} of String => Grip::Controllers::Base
      end

      def call(context : HTTP::Server::Context)
        call_next(context)
      rescue ex
        context.response.status_code = 500 if !context.response.status_code.in?([400, 401, 403, 404, 405, 500])

        if ex.is_a?(Grip::Exceptions::Base)
          context.response.status_code = ex.status_code
          call_exception(context, ex, ex.status_code)
        else
          call_exception(context, ex, context.response.status_code)
        end
      end

      private def call_exception(context : HTTP::Server::Context, exception : ::Exception, status_code : Int32)
        return context if context.response.closed?
        if @handlers.has_key?(exception.class.name)
          context.response.status_code = status_code
          context.exception = exception

          @handlers[exception.class.name].call(context)
        else
          if @environment == "production"
            context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
            context.response.print("An error occured, please try again later.")
          else
            context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
            context.response.print(Grip::Minuscule::ExceptionPage.for_runtime_exception(context, exception).to_s)
          end

          context
        end
      end
    end
  end
end
