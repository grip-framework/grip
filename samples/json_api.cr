require "grip"

class Index < Grip::Http
  route("/", ["GET"])

  def get(env)
    render(env, 200, {"message": "Hello, World!"})
  end
end

add_handlers [Index]

Grip.run
