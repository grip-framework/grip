require "grip"

class Index < Grip::HttpConsumer
  route("/", ["GET", "POST"])

  def get(env)
    {
      :ok,
      {"message": "Hello, World!"},
    }
  end

  def post(env)
    headers(env, {"content-type" => "application/json"})
    {
      :created,
      {"message": "Hello, World"},
    }
  end
end

add_handlers [Index]

Grip.run
