require "grip"

class Index < Grip::HttpConsumer
  route("/:id", ["GET"])

  def get(env)
    params = url?(env)
    # The default content type of every response is application/json
    {
      :ok,
      {"body": "Hello, World! #{params["id"]}"},
    }
  end
end

add_handlers [Index]

Grip.run
