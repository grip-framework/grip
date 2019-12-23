require "grip"

class IndexHandler < Grip::Handler
  route("/", ["GET"])

  def get(env)
    render(env, 200, {"message": "Hello, World!"})
  end
end

add_handlers [IndexHandler]

Grip.run
