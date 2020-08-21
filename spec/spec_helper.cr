require "spec"
require "../src/*"

include Grip

Spec.before_each do
  config = Grip.config
  config.env = "development"
end

class ForbiddenController < Grip::Controllers::Exception
  def call(context)
    context.response.headers.merge!({"Content-Type" => "text/html"})
    context.response.print("403 error")
    context
  end
end

class ExampleController < Grip::Controllers::Http
  def get(context)
    context
  end

  def post(context)
    context
  end

  def put(context)
    context
  end

  def delete(context)
    context
  end
end

class MatchController < Grip::Controllers::WebSocket
  def on_open(context, socket)
    socket.send("Match")
  end
end

class NoMatchController < Grip::Controllers::WebSocket
  def on_open(context, socket)
    socket.send("No Match")
  end
end

class UrlParametersController < Grip::Controllers::WebSocket
  def on_open(context, socket)
    url?(context)["id"]
  end
end

class BlankController < Grip::Controllers::WebSocket
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

def build_main_handler
  Grip.config.setup
  main_handler = Grip.config.handlers.first
  current_handler = main_handler
  Grip.config.handlers.each do |handler|
    current_handler.next = handler
    current_handler = handler
  end
  main_handler
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

Spec.after_each do
  Grip.config.clear
  Grip::Routers::Http::INSTANCE.routes = Radix::Tree(Grip::Routers::Route).new
  Grip::Routers::Http::INSTANCE.cached_routes = Hash(String, Radix::Result(Grip::Routers::Route)).new
  Grip::Routers::WebSocket::INSTANCE.routes = Radix::Tree(Grip::Routers::Route).new
end