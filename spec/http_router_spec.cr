require "./spec_helper"

describe "Grip::Routers::Http" do
  it "routes" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print("hello")
      context
    end

    request = HTTP::Request.new("GET", "/")
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("hello")
  end

  it "routes with long response body" do
    long_response_body = "string" * 10_000

    http_handler = Grip::Routers::Http.new
    http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print(long_response_body)
      context
    end

    request = HTTP::Request.new("GET", "/")
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq(long_response_body)
  end

  it "routes request with query string" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print("hello #{context.fetch_query_params.["message"]}")
      context
    end
    request = HTTP::Request.new("GET", "/?message=world")
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("hello world")
  end

  it "routes request with multiple query strings" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "GET", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print("hello #{context.fetch_query_params.["message"]} time #{context.fetch_query_params.["time"]}")
      context
    end

    request = HTTP::Request.new("GET", "/?message=world&time=now")
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("hello world time now")
  end

  it "route parameter has more precedence than query string arguments" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "GET", "/:message", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      context.response.print("hello #{context.fetch_path_params.["message"]}")
      context
    end
    request = HTTP::Request.new("GET", "/world?message=grip")
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("hello world")
  end

  it "parses simple JSON body" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "POST", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      name = context.fetch_json_params.["name"]
      age = context.fetch_json_params.["age"]
      context.response.print("Hello #{name} Age #{age}")
      context
    end

    json_payload = {"name": "Giorgi", "age": 20}
    request = HTTP::Request.new(
      "POST",
      "/",
      body: json_payload.to_json,
      headers: HTTP::Headers{"Content-Type" => "application/json"},
    )
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("Hello Giorgi Age 20")
  end

  it "parses JSON with string array" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "POST", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      skills = context.fetch_json_params.["skills"].as(Array)
      context.response.print("Skills #{skills.each.join(',')}")
      context
    end

    json_payload = {"skills": ["elixir", "crystal"]}
    request = HTTP::Request.new(
      "POST",
      "/",
      body: json_payload.to_json,
      headers: HTTP::Headers{"Content-Type" => "application/json"},
    )
    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("Skills elixir,crystal")
  end

  it "parses JSON with json object array" do
    http_handler = Grip::Routers::Http.new
    http_handler.add_route "POST", "/", ExampleController.new, nil, ->(context : HTTP::Server::Context) do
      skills = context.fetch_json_params.["skills"].as(Array)
      skills_from_languages = skills.map do |skill|
        skill["language"]
      end
      context.response.print("Skills #{skills_from_languages.each.join(',')}")
      context
    end

    json_payload = {"skills": [{"language": "elixir"}, {"language": "crystal"}]}
    request = HTTP::Request.new(
      "POST",
      "/",
      body: json_payload.to_json,
      headers: HTTP::Headers{"Content-Type" => "application/json"},
    )

    client_response = call_request_on_app(request, http_handler)
    client_response.body.should eq("Skills elixir,crystal")
  end
end
