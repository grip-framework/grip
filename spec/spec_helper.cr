require "spec"
require "../src/*"

include Grip

class ForbiddenController < Grip::Controllers::Exception
  def call(context : HTTP::Server::Context) : HTTP::Server::Context
    context
      .html("403 Error")
  end
end

class ExampleController < Grip::Controllers::Http
  def get(context : HTTP::Server::Context) : HTTP::Server::Context
    context
  end

  def post(context : HTTP::Server::Context) : HTTP::Server::Context
    context
  end

  def put(context : HTTP::Server::Context) : HTTP::Server::Context
    context
  end

  def delete(context : HTTP::Server::Context) : HTTP::Server::Context
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
    context
      .fetch_path_params
      .["id"]
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

def create_request_and_return_io_and_context(handler, request)
  io = IO::Memory.new
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  handler.call(context)
  response.close
  io.rewind
  {io, context}
end
