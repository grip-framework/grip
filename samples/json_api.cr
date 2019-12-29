require "grip"

class Index < Grip::Http
  route("/", ["GET", "POST"])

  def get(env)
    render(env, 200, {"message": "Hello, World!"})
  end

  def post(env)
    headers(env, {"content-type" => "application/json"})
    {"message": "Hello, World"}.to_json
  end
end

add_handlers [Index]

Grip.run
