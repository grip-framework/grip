require "spec"
require "../src/*"

include Grip

class ErrorController
  include Grip::Controllers::Exception

  def call(context : Context) : Context
    context
      .halt
  end
end

class ErrorApplication
  include Grip::Application

  property handlers : Array(HTTP::Handler) = [
    Grip::Handlers::Exception.new,
  ] of HTTP::Handler

  property host : String = "0.0.0.0"
  property port : Int32 = 0

  def initialize
    exception Grip::Exceptions::NotFound, ErrorController
  end
end

class HttpApplication
  include Grip::Application

  property handlers : Array(HTTP::Handler) = [
    Grip::Handlers::HTTP.new,
  ] of HTTP::Handler

  property host : String = "0.0.0.0"
  property port : Int32 = 0

  def initialize
    get "/", ExampleController
    get "/:id", ExampleController, as: :index
  end
end

class ServerSentApplication
  include Grip::Application

  property handlers : Array(::HTTP::Handler) = [
    Grip::Handlers::ServerSent.new,
  ] of ::HTTP::Handler

  property host : String = "0.0.0.0"
  property port : Int32 = 0

  def initialize
    sse "/", ServerSentExampleController, as: :stream
    sse "/wallet/stream", WalletStreamController, as: :stream
    sse "/large", LargePayloadController, as: :stream
  end
end

class WebSocketApplication
  include Grip::Application

  property handlers : Array(HTTP::Handler) = [
    Grip::Handlers::WebSocket.new,
  ] of HTTP::Handler

  property host : String = "0.0.0.0"
  property port : Int32 = 0

  def initialize
    ws "/", MatchController
  end
end

class ForbiddenController
  include Grip::Controllers::Exception

  def call(context : Context) : Context
    context
      .html("403 Error")
  end
end

class ExampleController
  include Grip::Controllers::HTTP

  def index(context : Context) : Context
    context
  end

  def get(context : Context) : Context
    context
  end

  def post(context : Context) : Context
    context
  end

  def put(context : Context) : Context
    context
  end

  def delete(context : Context) : Context
    context
  end
end

class ServerSentExampleController
  include Grip::Controllers::ServerSent

  def stream(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
    stream = context.stream

    # Emit handshake/data frame so specs can assert against response body
    stream.connected("conn_test_123")

    sleep 0.1 # Allow time for the background worker fiber to flush to socket
    context.halt
  end
end

class WalletStreamController
  include Grip::Controllers::ServerSent

  def stream(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
    stream = context.stream

    payload = {
      "amount"   => 10.5,
      "currency" => "USD",
    }

    stream.emit(
      Grip::ServerSent::Event::Type::Data,
      data: payload,
      id: 1001
    )

    sleep 0.1
    context.halt
  end
end

class LargePayloadController
  include Grip::Controllers::ServerSent

  def stream(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
    stream = context.stream
    large_payload = "x" * 10_000

    stream.emit(Grip::ServerSent::Event::Type::Data, data: large_payload)

    sleep 0.1
    context.halt
  end
end

class MatchController
  include Grip::Controllers::WebSocket

  def on_open(context, socket) : Void
    socket.send("Match")
  end

  def on_ping(context : Context, socket : Socket, message : String) : Void
  end

  def on_pong(context : Context, socket : Socket, message : String) : Void
  end

  def on_message(context : Context, socket : Socket, message : String) : Void
  end

  def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
  end

  def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
  end
end

class NoMatchController
  include Grip::Controllers::WebSocket

  def on_open(context, socket) : Void
    socket.send("No Match")
  end

  def on_ping(context : Context, socket : Socket, message : String) : Void
  end

  def on_pong(context : Context, socket : Socket, message : String) : Void
  end

  def on_message(context : Context, socket : Socket, message : String) : Void
  end

  def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
  end

  def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
  end
end

class UrlParametersController
  include Grip::Controllers::WebSocket

  def on_open(context, socket) : Void
    context
      .fetch_path_params
      .["id"]
  end

  def on_ping(context : Context, socket : Socket, message : String) : Void
  end

  def on_pong(context : Context, socket : Socket, message : String) : Void
  end

  def on_message(context : Context, socket : Socket, message : String) : Void
  end

  def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
  end

  def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
  end
end

class BlankController
  include Grip::Controllers::WebSocket

  def on_open(context : Context, socket : Socket) : Void
  end

  def on_ping(context : Context, socket : Socket, message : String) : Void
  end

  def on_pong(context : Context, socket : Socket, message : String) : Void
  end

  def on_message(context : Context, socket : Socket, message : String) : Void
  end

  def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
  end

  def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
  end
end

def create_ws_request_and_return_io_and_context(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)

  context = HTTP::Server::Context.new(request, response)
  begin
    handler.call context
  rescue IO::Error
    # Raises because the IO::Memory is empty
  end

  {% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
    response.upgrade_handler.try &.call(io)
  {% end %}

  io.rewind
  {io, context}
end

def call_request_on_app(request, handler)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

def call_request_on_app(request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  main_handler = build_main_handler
  main_handler.call context
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

def router
  [
    Grip::Handlers::Log.new,
    Grip::Handlers::Exception.new,
  ] of HTTP::Handler
end

def build_main_handler
  main_handler = router[0]
  current_handler = main_handler
  router.each do |handler|
    current_handler.next = handler
    current_handler = handler
  end
  main_handler
end

def create_request_and_return_io(router, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  router.call(context)
  response.close
  io.rewind
  HTTP::Client::Response.from_io(io, decompress: false)
end

def create_request_and_return_io_and_context(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end
