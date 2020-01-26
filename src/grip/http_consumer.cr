require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class HttpConsumer < BaseConsumer
    @@handler_methods : Array(String) = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]

    def initialize(handler_path)
      @@handler_path = handler_path

      @@handler_methods.each do |method|
        Grip::HttpRouteHandler::INSTANCE.add_route(method.upcase, handler_path, self)
      end
    end

    # Helper methods for control flow manipulation, etc.
    def redirect(env, to)
      env.redirect to
    end

    # get post put patch delete options
    def get(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def post(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def put(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def patch(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def delete(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def options(env : HTTP::Server::Context)
      env.response.status_code = 404
    end

    def call(env : HTTP::Server::Context)
      case env.request.method
      when "GET"
        get(env)
      when "POST"
        post(env)
      when "PUT"
        put(env)
      when "PATCH"
        patch(env)
      when "DELETE"
        delete(env)
      when "OPTIONS"
        options(env)
      else
        call_next(env)
      end
    end

    macro json
      env.params.json
    end

    macro query
      env.params.query
    end

    macro url
      env.params.url
    end

    macro headers
      env.request.headers
    end

    def to_s(io)
      io << "[\u001b[32minfo\u001b[0m] #{typeof(self)} registered at '" << @@handler_path << "' and is reachable via a HTTP connection."
    end
  end
end
