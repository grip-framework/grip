require "grip"

class IndexHandler < Grip::Handler
  route("/", ["GET"])

  def get(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, World!", "text/html")
  end
end

index = IndexHandler.new

add_handlers [index]

Grip.run
