require "./spec_helper"

describe "Grip::Handlers::Exception" do
  it "renders 404 on route not found" do
    request = HTTP::Request.new("GET", "/asd")
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    Grip::Handlers::Exception.new.call(context)
    response.close
    io.rewind
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
  end

  it "renders custom error" do
    error_handler = Grip::Handlers::Exception.new
    error_handler.handlers[403] = ForbiddenController.new
    http_handler = Grip::Routers::Http.new

    http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
      raise Exceptions::Forbidden.new
      context
    end

    request = HTTP::Request.new("GET", "/")
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    error_handler.next = http_handler
    error_handler.call(context)
    response.close
    io.rewind
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 403
    response.headers["Content-Type"].should eq "text/html; charset=UTF-8"
    response.body.should eq "403 Error"
  end
end
