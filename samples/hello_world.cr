require "grip"

class IndexHandler < Grip::Handler
  route("/:id", ["GET"])

  def get(env)
    render(env, 200, "Hello, World! #{env.params.url["id"]}", "text/html")
  end
end

add_handlers [IndexHandler]

Grip.run
