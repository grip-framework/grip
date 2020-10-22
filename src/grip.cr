require "http"
require "http/web_socket"
require "json"
require "uri"
require "radix"
require "base64"
require "uuid"
require "crypto/subtle"
require "exceptions"
require "pipes"
require "exception_page"
require "swagger"

{% if flag?(:with_openssl) %}
  require "openssl/sha1"
{% else %}
  require "digest/sha1"
{% end %}

require "./grip/annotations/*"
require "./grip/support/*"
require "./grip/minuscule/*"
require "./grip/parsers/*"
require "./grip/dsl/*"
require "./grip/extensions/*"
require "./grip/handlers/*"
require "./grip/controllers/*"
require "./grip/routers/route"
require "./grip/routers/*"
require "./grip/*"

module Grip; end

class IndexController < Grip::Controllers::Http
  def get(context : Context) : Context
    context
      .put_status(404)   # Assign the status code to 200 OK.
      .json({"id" => 1}) # Respond with JSON content.
      .halt              # Close the connection.
  end

  def index(context : Context) : Context
    id =
      context
        .fetch_path_params
        .["id"]

    # An optional secondary argument gives a custom `Content-Type` header to the response.
    context
      .json(content: {"id" => id}, content_type: "application/json; charset=us-ascii")
  end
end

class WebSocketController < Grip::Controllers::WebSocket
  def on_open(context) : Void
    send("Match")
  end

  def on_ping(context : Context, message : String) : Void
    send("PONG")
  end

  def on_pong(context : Context, message : String) : Void
    send("PING")
  end

  def on_message(context : Context, message : String) : Void
    send(message)
  end

  def on_binary(context : Context, binary : Bytes) : Void
    send(binary)
  end

  def on_close(context : Context, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
  end
end

class Application < Grip::Application
  def routes
    pipeline :api, [
      Pipes::PoweredByHeader.new,
    ]

    pipeline :web, [
      Pipes::SecureHeaders.new,
    ]

    scope "/api/v1" do
      pipe_through [:web, :api]

      get "/", IndexController
    end

    ws "/", WebSocketController
    get "/:id", IndexController, as: :index
  end

  def directory_listing
    true
  end
end

app = Application.new
app.run
