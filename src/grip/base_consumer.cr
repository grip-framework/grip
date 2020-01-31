module Grip
  abstract class BaseConsumer
    include HTTP::Handler

    def match?(env : HTTP::Server::Context)
      env.route_found? || env.ws_route_found?
    end

    def call(env : HTTP::Server::Context)
      call_next(env)
    end
  end
end
