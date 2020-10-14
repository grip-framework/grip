require "./spec_helper"

describe "ParameterBox" do
  it "parses query params" do
    request = HTTP::Request.new("POST", "/?hello=world")
    query_params = Grip::Parsers::ParameterBox.new(request).query
    query_params["hello"].should eq "world"
  end

  it "parses multiple values for query params" do
    request = HTTP::Request.new("POST", "/?hello=world&hello=crystal")
    query_params = Grip::Parsers::ParameterBox.new(request).query
    query_params.fetch_all("hello").should eq ["world", "crystal"]
  end

  it "parses url params" do
    grip = Grip::Routers::Http.new
    grip.add_route "POST", "/hello/:name", ExampleController.new, nil, nil
    request = HTTP::Request.new("POST", "/hello/crystal")
    _context = create_request_and_return_io_and_context(grip, request)[1]
    url_params = Grip::Parsers::ParameterBox.new(request, grip.lookup_route(request.method, request.path).params).url
    url_params["name"].should eq "crystal"
  end

  it "decodes url params" do
    grip = Grip::Routers::Http.new
    grip.add_route "POST", "/hello/:email/:money/:spanish", ExampleController.new, nil, nil
    request = HTTP::Request.new("POST", "/hello/sam%2Bspec%40gmail.com/%2419.99/a%C3%B1o")
    _context = create_request_and_return_io_and_context(grip, request)[1]
    url_params = Grip::Parsers::ParameterBox.new(request, grip.lookup_route(request.method, request.path).params).url
    url_params["email"].should eq "sam+spec@gmail.com"
    url_params["money"].should eq "$19.99"
    url_params["spanish"].should eq "año"
  end

  it "parses request body" do
    request = HTTP::Request.new(
      "POST",
      "/?hello=world",
      body: "name=crystal&version=0.35.1",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"},
    )

    query_params = Grip::Parsers::ParameterBox.new(request).query
    {"hello" => "world"}.each do |k, v|
      query_params[k].should eq(v)
    end

    body_params = Grip::Parsers::ParameterBox.new(request).body
    {"name" => "crystal", "version" => "0.35.1"}.each do |k, v|
      body_params[k].should eq(v)
    end
  end

  it "parses multiple values in request body" do
    request = HTTP::Request.new(
      "POST",
      "/",
      body: "hello=world&hello=crystal",
      headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"},
    )

    body_params = Grip::Parsers::ParameterBox.new(request).body
    body_params.fetch_all("hello").should eq(["world", "crystal"])
  end

  context "when content type is application/json" do
    it "parses request body" do
      request = HTTP::Request.new(
        "POST",
        "/",
        body: "{\"name\": \"Crystal\"}",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
      )

      json_params = Grip::Parsers::ParameterBox.new(request).json
      json_params.should eq({"name" => "Crystal"})
    end

    it "parses request body when passed charset" do
      request = HTTP::Request.new(
        "POST",
        "/",
        body: "{\"name\": \"Crystal\"}",
        headers: HTTP::Headers{"Content-Type" => "application/json; charset=utf-8"},
      )

      json_params = Grip::Parsers::ParameterBox.new(request).json
      json_params.should eq({"name" => "Crystal"})
    end

    it "parses request body for array" do
      request = HTTP::Request.new(
        "POST",
        "/",
        body: "[1]",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
      )

      json_params = Grip::Parsers::ParameterBox.new(request).json
      json_params.should eq({"_json" => [1]})
    end

    it "parses request body and query params" do
      request = HTTP::Request.new(
        "POST",
        "/?foo=bar",
        body: "[1]",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
      )

      query_params = Grip::Parsers::ParameterBox.new(request).query
      {"foo" => "bar"}.each do |k, v|
        query_params[k].should eq(v)
      end

      json_params = Grip::Parsers::ParameterBox.new(request).json
      json_params.should eq({"_json" => [1]})
    end

    it "handles no request body" do
      request = HTTP::Request.new(
        "GET",
        "/",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
      )

      url_params = Grip::Parsers::ParameterBox.new(request).url
      url_params.should eq({} of String => String)

      query_params = Grip::Parsers::ParameterBox.new(request).query
      query_params.to_s.should eq("")

      body_params = Grip::Parsers::ParameterBox.new(request).body
      body_params.to_s.should eq("")

      json_params = Grip::Parsers::ParameterBox.new(request).json
      json_params.should eq({} of String => Nil | String | Int64 | Float64 | Bool | Hash(String, JSON::Any) | Array(JSON::Any))
    end
  end

  context "when content type is incorrect" do
    it "does not parse request body" do
      request = HTTP::Request.new(
        "POST",
        "/?hello=world",
        body: "name=crystal&version=0.35.1",
        headers: HTTP::Headers{"Content-Type" => "text/plain"},
      )

      query_params = Grip::Parsers::ParameterBox.new(request).query
      query_params["hello"].should eq("world")

      body_params = Grip::Parsers::ParameterBox.new(request).body
      body_params.to_s.should eq("")
    end
  end
end
