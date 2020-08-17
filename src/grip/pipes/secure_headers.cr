module Grip
  module Pipes
    class SecureHeaders < Base
      def call(context : HTTP::Server::Context)
        context.response.headers["X-XSS-Protection"] = "1; mode=block" unless context.response.headers.has_key?("X-XSS-Protection")
        context.response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains; preload" unless context.response.headers.has_key?("Strict-Transport-Security")
        context.response.headers["X-Frame-Options"] = "DENY" unless context.response.headers.has_key?("X-Frame-Options")
        context.response.headers["X-Content-Type-Options"] = "nosniff" unless context.response.headers.has_key?("X-Content-Type-Options")
        context.response.headers["Content-Security-Policy"] = "default-src 'self'" unless context.response.headers.has_key?("Content-Security-Policy")
        context.response.headers["X-Permitted-Cross-Domain-Policies"] = "none" unless context.response.headers.has_key?("X-Permitted-Cross-Domain-Policies")
        context.response.headers["Referrer-Policy"] = "same-origin" unless context.response.headers.has_key?("Referrer-Policy")
      end
    end
  end
end
