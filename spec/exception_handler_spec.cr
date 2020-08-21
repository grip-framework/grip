require "./spec_helper"

describe "Grip::Handlers::Exception" do
  it "renders 404 on route not found" do
    request = HTTP::Request.new("GET", "/asd")
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    Grip::Handlers::Exception::INSTANCE.call(context)
    response.close
    io.rewind
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 404
  end

  it "renders custom error" do
    Grip.config.add_error_handler(403, ForbiddenController.new)

    Grip::Routers::Http::INSTANCE.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.status_code = 403
      context
    end

    request = HTTP::Request.new("GET", "/")
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    Grip::Handlers::Exception::INSTANCE.next = Grip::Routers::Http::INSTANCE
    Grip::Handlers::Exception::INSTANCE.call(context)
    response.close
    io.rewind
    response = HTTP::Client::Response.from_io(io, decompress: false)
    response.status_code.should eq 403
    response.headers["Content-Type"].should eq "text/html"
    response.body.should eq "403 error"
  end
end
