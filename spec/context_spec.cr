require "./spec_helper"

describe "Context" do
  context "headers" do
    it "sets content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/content_type", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.response.headers.merge!({"Content-Type" => "application/json"})
        context
      end

      request = HTTP::Request.new("GET", "/content_type")
      client_response = call_request_on_app(request, http_handler)
      client_response.headers["Content-Type"].should eq("application/json")
    end

    it "parses headers" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/headers", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        name = context.request.headers["name"]
        context.response.print("Hello #{name}")
        context
      end

      headers = HTTP::Headers.new
      headers["name"] = "grip"
      request = HTTP::Request.new("GET", "/headers", headers)
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "Hello grip"
    end

    it "sets response headers" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/response_headers", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.response.headers.add "Accept-Language", "ge"
        context
      end

      request = HTTP::Request.new("GET", "/response_headers")
      client_response = call_request_on_app(request, http_handler)
      client_response.headers["Accept-Language"].should eq "ge"
    end
  end

  context "methods" do
    it "has binary() method with octet-stream" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.binary(10).halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "10"
      ("octet-stream".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes text in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.text("👋🏼 grip").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "👋🏼 grip"
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes json in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.json({:message => "👋🏼 grip"}).halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "{\"message\":\"👋🏼 grip\"}"
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes html in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.html("👋🏼 grip").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "👋🏼 grip"
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_true
    end
  end

  context "methods" do
    it "allows overriding text() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.text("👋🏼 grip", "text/html").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding json() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.json({:message => "👋🏼 grip"}, "application/json").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding html() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.html("👋🏼 grip", "text/html").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding binary() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.binary(10, "multipart/encrypted").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.headers["Content-Type"].should eq "multipart/encrypted"
    end
  end
end
