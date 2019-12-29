require "grip"

class Index < Grip::Http
  route("/:id", ["GET"])

  def get(env)
    params = url?(env)
    "Hello, World! #{params["id"]}"
  end
end

add_handlers [Index]

Grip.run
