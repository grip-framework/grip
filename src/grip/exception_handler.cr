module Grip
  # Handles all the exceptions, including 404, custom errors and 500.
  class ExceptionHandler
    include HTTP::Handler
    INSTANCE = new

    def call(context : HTTP::Server::Context)
      call_next(context)
    rescue ex : Grip::Exceptions::RouteNotFound
      call_exception_with_status_code(context, ex, 404)
    rescue ex : Grip::Exceptions::CustomException
      call_exception_with_status_code(context, ex, context.response.status_code)
    rescue ex : Exception
      log("Exception: #{ex.inspect_with_backtrace}")
      return call_exception_with_status_code(context, ex, 500) if Grip.config.error_handlers.has_key?(500)
      verbosity = Grip.config.env == "production" ? false : true

      context.response.status_code = 500
      context.response.content_type = "application/json"
      context.response.print({"status": "error", "message": "internal_server_error"}.to_json)
      context
    end

    private def call_exception_with_status_code(context : HTTP::Server::Context, exception : Exception, status_code : Int32)
      return if context.response.closed?
      if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(status_code)
        context.response.content_type = "text/html" unless context.response.headers.has_key?("Content-Type")
        context.response.status_code = status_code
        context.response.print Grip.config.error_handlers[status_code].call(context, exception)
        context
      end
    end
  end
end
