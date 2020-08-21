require "./spec_helper"

describe "Context" do
  context "headers" do
    it "sets content type" do
      Grip::Routers::Http::INSTANCE.add_route "GET", "/content_type", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.response.headers.merge!({"Content-Type" => "application/json"})
        context
      end 

      request = HTTP::Request.new("GET", "/content_type")
      client_response = call_request_on_app(request)
      client_response.headers["Content-Type"].should eq("application/json")
    end

    it "parses headers" do
      Grip::Routers::Http::INSTANCE.add_route "GET", "/headers", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        name = context.request.headers["name"]
        context.response.print("Hello #{name}")
        context
      end 

      headers = HTTP::Headers.new
      headers["name"] = "grip"
      request = HTTP::Request.new("GET", "/headers", headers)
      client_response = call_request_on_app(request)
      client_response.body.should eq "Hello grip"
    end

    it "sets response headers" do
      Grip::Routers::Http::INSTANCE.add_route "GET", "/response_headers", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
        context.response.headers.add "Accept-Language", "ge"
        context
      end 

      request = HTTP::Request.new("GET", "/response_headers")
      client_response = call_request_on_app(request)
      client_response.headers["Accept-Language"].should eq "ge"
    end
  end
end