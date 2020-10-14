require "./spec_helper"

describe "Grip::Routers::WebSocket" do
  it "doesn't match on wrong route" do
    handler = Grip::Routers::WebSocket.new
    handler.next = Grip::Routers::Http.new
    headers = HTTP::Headers{
      "Upgrade"           => "websocket",
      "Connection"        => "Upgrade",
      "Sec-WebSocket-Key" => "dGhlIHNhbXBsZSBub25jZQ==",
    }
    request = HTTP::Request.new("GET", "/asd", headers)
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)

    expect_raises(Exceptions::NotFound) do
      handler.call context
    end
  end

  it "matches on given route" do
    handler = Grip::Routers::WebSocket.new
    handler.add_route "/", MatchController.new, nil, nil
    handler.add_route "/no_match", NoMatchController.new, nil, nil
    headers = HTTP::Headers{
      "Upgrade"               => "websocket",
      "Connection"            => "Upgrade",
      "Sec-WebSocket-Key"     => "dGhlIHNhbXBsZSBub25jZQ==",
      "Sec-WebSocket-Version" => "13",
    }
    request = HTTP::Request.new("GET", "/", headers)

    io_with_context = create_ws_request_and_return_io_and_context(handler, request)[0]
    io_with_context.to_s.should eq("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n\r\n\x81\u0005Match")
  end

  it "fetches named url parameters" do
    handler = Grip::Routers::WebSocket.new
    handler.add_route "/:id", UrlParametersController.new, nil, nil
    headers = HTTP::Headers{
      "Upgrade"               => "websocket",
      "Connection"            => "Upgrade",
      "Sec-WebSocket-Key"     => "dGhlIHNhbXBsZSBub25jZQ==",
      "Sec-WebSocket-Version" => "13",
    }
    request = HTTP::Request.new("GET", "/1234", headers)
    io_with_context = create_ws_request_and_return_io_and_context(handler, request)[0]
    io_with_context.to_s.should eq("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=\r\n\r\n")
  end

  it "matches correct verb" do
    grip = Grip::Routers::Http.new
    handler = Grip::Routers::WebSocket.new
    handler.next = grip

    handler.add_route "/", BlankController.new, nil, nil

    grip.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print("get")
      context
    end

    request = HTTP::Request.new("GET", "/")
    io = IO::Memory.new
    response = HTTP::Server::Response.new(io)
    context = HTTP::Server::Context.new(request, response)
    handler.call(context)
    response.close
    io.rewind
    client_response = HTTP::Client::Response.from_io(io, decompress: false)
    client_response.body.should eq("get")
  end
end
