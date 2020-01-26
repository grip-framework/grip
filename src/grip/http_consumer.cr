require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class HttpConsumer < BaseConsumer
    @@handler_methods : Array(String) = ["GET", "POST", "PUT", "DELETE"]

    def initialize(handler_path)
      @@handler_path = handler_path

      @@handler_methods.each do |method|
        Grip::HttpRouteHandler::INSTANCE.add_route(method.upcase, handler_path, self)
      end
    end

    # Helper methods for control flow manipulation, etc.
    def redirect(req, to)
      req.redirect to
    end

    # get post put patch delete options
    def read(req : HTTP::Server::Context)
      req.response.status_code = 405
    end

    def create(req : HTTP::Server::Context)
      req.response.status_code = 405
    end

    def update(req : HTTP::Server::Context)
      req.response.status_code = 405
    end

    def delete(req : HTTP::Server::Context)
      req.response.status_code = 405
    end

    def call(req : HTTP::Server::Context)
      case req.request.method
      when "GET"
        read(req)
      when "POST"
        create(req)
      when "PUT"
        update(req)
      when "DELETE"
        delete(req)
      else
        call_next(req)
      end
    end

    macro json
      req.params.json
    end

    macro query
      req.params.query
    end

    macro url
      req.params.url
    end

    macro headers
      req.request.headers
    end

    def to_s(io)
      io << "[\u001b[32minfo\u001b[0m] #{typeof(self)} registered at '" << @@handler_path << "' and is reachable via a HTTP connection."
    end
  end
end
