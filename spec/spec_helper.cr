require "spec"
require "../src/*"

include Grip

Spec.before_each do
  config = Grip.config
  config.env = "development"
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