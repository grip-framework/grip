module Grip
  class BaseConsumer
    include HTTP::Handler
    @@handler_path = String.new
    @@handler_methods = Array(String).new

    def to_s(io)
      if @@handler_methods.size > 1
        io << "[\u001b[32m#{typeof(self)}\u001b[0m] registered at '" << @@handler_path << "' and is reachable via '" << @@handler_methods << "' methods."
      else
        io << "[\u001b[32m#{typeof(self)}\u001b[0m] registered at '" << @@handler_path << "' and is reachable via a '" << @@handler_methods[0] << "' method."
      end
    end

    macro route(path, methods = ["GET"])
      @@handler_path = {{path}}
      {{methods}}.each do |method|
        @@handler_methods.push(method)
      end
    end

    def match?(env : HTTP::Server::Context)
      env.route_found? || env.ws_route_found?
    end

    def call(env : HTTP::Server::Context)
      call_next(env)
    end
  end
end
