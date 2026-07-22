require "./spec_helper"

describe Grip::Handlers::ServerSent do
  it "routes and sets server-sent event headers" do
    server_sent = Grip::Handlers::ServerSent.new
    server_sent.add_route "GET", "/sse", ServerSentExampleController.new, [:none], ->(context : ::HTTP::Server::Context) do
      stream = context.stream
      stream.connected("conn_123")

      sleep 0.1
      context
    end

    request = ::HTTP::Request.new("GET", "/sse")
    client_response = call_request_on_app(request, server_sent)

    # Verify headers required by the SSE specification
    client_response.headers["Content-Type"].should eq("text/event-stream; charset=utf-8")
    client_response.headers["Cache-Control"].should eq("no-cache")
    client_response.headers["X-Accel-Buffering"].should eq("no")

    # Verify connection frame output payload (TitleCase event + envelope payload)
    client_response.body.should contain("event: Connected\n")
    client_response.body.should contain("\"connection_id\":\"conn_123\"")
  end

  it "routes and streams structured SSE data frames" do
    server_sent = Grip::Handlers::ServerSent.new
    server_sent.add_route "GET", "/wallet/stream", ServerSentExampleController.new, [:none], ->(context : ::HTTP::Server::Context) do
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
      context
    end

    request = ::HTTP::Request.new("GET", "/wallet/stream")
    client_response = call_request_on_app(request, server_sent)

    # Verify stream output structure
    client_response.body.should contain("event: Data\n")
    client_response.body.should contain("id: 1001\n")
    client_response.body.should contain("\"amount\":10.5,\"currency\":\"USD\"")
  end

  it "handles large payloads across multiple raw chunks" do
    large_payload = "x" * 10_000

    server_sent = Grip::Handlers::ServerSent.new
    server_sent.add_route "GET", "/large", ServerSentExampleController.new, [:none], ->(context : ::HTTP::Server::Context) do
      stream = context.stream
      stream.emit(Grip::ServerSent::Event::Type::Data, data: large_payload)

      sleep 0.1
      context
    end

    request = ::HTTP::Request.new("GET", "/large")
    client_response = call_request_on_app(request, server_sent)

    client_response.body.should contain(large_payload)
  end
end
