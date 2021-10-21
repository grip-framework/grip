require "./spec_helper"

describe "Context" do
  context "headers" do
    it "sets content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/content_type", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.response.headers.merge!({"Content-Type" => "application/json"})
        context
      end

      request = HTTP::Request.new("GET", "/content_type")
      client_response = call_request_on_app(request, http_handler)
      client_response.headers["Content-Type"].should eq("application/json")
    end

    it "parses headers" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/headers", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
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
      http_handler.add_route "GET", "/response_headers", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
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
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.binary(10).halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "10"
      ("octet-stream".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes text in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.text("👋🏼 grip").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "👋🏼 grip"
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes json in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.json({:message => "👋🏼 grip"}).halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.body.should eq "{\"message\":\"👋🏼 grip\"}"
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_true
    end

    it "encodes html in utf-8" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
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
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.text("👋🏼 grip", "text/html").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding json() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.json({:message => "👋🏼 grip"}, "application/json").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding html() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.html("👋🏼 grip", "text/html").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      ("UTF-8".in? client_response.headers["Content-Type"]).should be_false
    end

    it "allows overriding binary() content type" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.binary(10, "multipart/encrypted").halt
      end

      request = HTTP::Request.new("GET", "/")
      client_response = call_request_on_app(request, http_handler)
      client_response.headers["Content-Type"].should eq "multipart/encrypted"
    end
  end

  context "cookies" do
    it "sets cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/cookies", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.put_resp_cookie(HTTP::Cookie.new("Foo", "Bar")).halt
      end

      request = HTTP::Request.new("GET", "/cookies")
      client_response = call_request_on_app(request, http_handler)

      client_response.cookies.size.should eq(1)
      client_response.cookies["Foo"].value.should eq("Bar")
    end

    it "sets string cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/cookies", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.put_resp_cookie("Foo", "Bar").halt
      end

      request = HTTP::Request.new("GET", "/cookies")
      client_response = call_request_on_app(request, http_handler)

      client_response.cookies.size.should eq(1)
      client_response.cookies["Foo"].value.should eq("Bar")
    end

    it "sets multiple cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/cookies", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.put_resp_cookie("Foo", "Bar").put_resp_cookie("Qux", "Baz").halt
      end

      request = HTTP::Request.new("GET", "/cookies")
      client_response = call_request_on_app(request, http_handler)

      client_response.cookies.size.should eq(2)
      client_response.cookies["Foo"].value.should eq("Bar")
      client_response.cookies["Qux"].value.should eq("Baz")
    end

    it "overrides cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/cookies", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.put_resp_cookie("Foo", "Bar").put_resp_cookie("Foo", "Baz").halt
      end

      request = HTTP::Request.new("GET", "/cookies")
      client_response = call_request_on_app(request, http_handler)

      client_response.cookies.size.should eq(1)
      client_response.cookies["Foo"].value.should eq("Baz")
    end

    it "gets correkt cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/get_cookie", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        cookie = context.get_req_cookie("Foo")
        if cookie
          context.response.print(cookie.value)
        else
          context.response.print("nil")
        end
        context
      end

      request = HTTP::Request.new("GET", "/get_cookie")
      request.cookies["Foo"] = "Bar"
      client_response = call_request_on_app(request, http_handler)

      client_response.body.should eq "Bar"
    end

    it "gets nil for not existing cookie" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/get_cookie", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        cookie = context.get_req_cookie("Baz")
        if cookie
          context.response.print(cookie.value)
        else
          context.response.print("nil")
        end

        context
      end

      request = HTTP::Request.new("GET", "/get_cookie")
      request.cookies["Foo"] = "Bar"
      client_response = call_request_on_app(request, http_handler)

      client_response.body.should eq "nil"
    end
  end

  context "redirects" do
    it "redirects to home page when called without arguments" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/redirect_to_home", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.redirect
      end

      request = HTTP::Request.new("GET", "/redirect_to_home")
      client_response = call_request_on_app(request, http_handler)

      client_response.headers["Location"].should eq("/")
      client_response.status_code.should eq(302)
    end

    it "redirects to another url with status code 301 using keyword arguments" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/redirect_to_another_url", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.redirect(url: "/another_url", status_code: 301)
      end

      request = HTTP::Request.new("GET", "/redirect_to_another_url")
      client_response = call_request_on_app(request, http_handler)

      client_response.headers["Location"].should eq("/another_url")
      client_response.status_code.should eq(301)
    end

    it "redirects to another url with status code 308 using positional arguments" do
      http_handler = Grip::Routers::Http.new
      http_handler.add_route "GET", "/redirect_to_another_url_with_308", ExampleController.new, [:none], ->(context : HTTP::Server::Context) do
        context.redirect("/another_url", HTTP::Status::PERMANENT_REDIRECT)
      end

      request = HTTP::Request.new("GET", "/redirect_to_another_url_with_308")
      client_response = call_request_on_app(request, http_handler)

      client_response.headers["Location"].should eq("/another_url")
      client_response.status_code.should eq(308)
    end
  end
end
