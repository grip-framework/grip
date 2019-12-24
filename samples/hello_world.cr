require "grip"

class Index < Grip::Http
  route("/:id", ["GET"])

  def get(env)
    headers(env, "Authorization", "Basic YWRtaW46YWRtaW4=")
    render(env, 200, "Hello, World! #{url?(env)["id"]}", "text/html")
  end
end

add_handlers [Index]

Grip.run
