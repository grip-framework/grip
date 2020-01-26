module Grip
  class BaseConsumer
    include HTTP::Handler

    @@handler_path = String.new
    def initialize(handler_path)
      @@handler_path = handler_path
    end

    def match?(env : HTTP::Server::Context)
      env.route_found? || env.ws_route_found?
    end

    def call(env : HTTP::Server::Context)
      call_next(env)
    end
  end
end
