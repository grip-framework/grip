require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class HttpConsumer < BaseConsumer
    def initialize
      @@handler_methods.each do |method|
        Grip::HttpRouteHandler::INSTANCE.add_route(method.upcase, @@handler_path, self)
      end
    end

    # Helper methods for control flow manipulation, etc.
    def redirect(env, to)
      env.redirect to
    end

    # get post put patch delete options
    def get(env : HTTP::Server::Context)
      call_next(env)
    end

    def post(env : HTTP::Server::Context)
      call_next(env)
    end

    def put(env : HTTP::Server::Context)
      call_next(env)
    end

    def patch(env : HTTP::Server::Context)
      call_next(env)
    end

    def delete(env : HTTP::Server::Context)
      call_next(env)
    end

    def options(env : HTTP::Server::Context)
      call_next(env)
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

    def json(env : HTTP::Server::Context)
      env.params.json
    end

    def query(env : HTTP::Server::Context)
      env.params.query
    end

    def url(env : HTTP::Server::Context)
      env.params.url
    end

    def headers(env : HTTP::Server::Context)
      env.request.headers
    end

    def to_s(io)
      if @@handler_methods.size > 1
        io << "[\u001b[32m#{typeof(self)}\u001b[0m] registered at '" << @@handler_path << "' and is reachable via '" << @@handler_methods << "' methods."
      else
        io << "[\u001b[32m#{typeof(self)}\u001b[0m] registered at '" << @@handler_path << "' and is reachable via a '" << @@handler_methods[0] << "' method."
      end
    end
  end
end
