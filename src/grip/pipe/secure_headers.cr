module Grip
  module Pipe
    class SecureHeaders < Base
      def call(context : HTTP::Server::Context)
        context.response.headers["X-XSS-Protection"] = "1; mode=block"
        context.response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload"
        context.response.headers["X-Frame-Options"] = "DENY"
        context.response.headers["X-Content-Type-Options"] = "nosniff"
        context.response.headers["Content-Security-Policy"] = "default-src 'self'"
        context.response.headers["X-Permitted-Cross-Domain-Policies"] = "none"
        context.response.headers["Referrer-Policy"] = "same-origin"
      end
    end
  end
end
