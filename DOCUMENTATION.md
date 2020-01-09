# Getting Started

This guide assumes that you already have Crystal installed. If not, check out the [Crystal installation methods](https://crystal-lang.org/install/) and come back when you’re done.

Keep in mind that this framework is not for HTML based request-response model, it only supports a JSON pure REST based API model, it is possible to switch to HTML via some hacking but it is not recommended.

Most of the legacy `cookbook` parts still work in Grip, the configuration parts are still the same.

## Installing Grip

First you need to create your application:

```bash
$ crystal init app your_app
$ cd your_app
```

Then add *Grip* to your `shard.yml` file as a dependencie.

```yaml
dependencies:
    grip:
        github: grkek/grip
```

Finally run `shards` to get the dependencies:

```bash
$ shards install
```

## Using Grip

Let's start with a simple example

```ruby
require "grip"

class Index < Grip::HttpConsumer
    route "/", ["GET"]

    def get(env)
        {:ok, "Hello, World!"}
    end
end

add_handlers [Index]

# Add the default routers to the stack
Grip.config.add_router Grip::HttpRouteHandler::INSTANCE
Grip.config.add_router Grip::WebSocketRouteHandler::INSTANCE

Grip.run
```

## Running Grip

Starting your application is easy, simply run:

```bash
$ crystal run src/your_app.cr
```

If everything went well you should see a message that your route was registered.

# Routing and Response

## Routes
You can handle HTTP methods via pre-defining a set of available methods and then creating separate handlers for each. Each consumer is a separate resource located a single route, which uses radix trees for additional flexibility.

```ruby
class Index < Grip::HttpConsumer
    route "/", ["GET", "POST", "PUT", "PATCH"]

    def get(env)
    .. show something ..
    end

    def post(env)
    .. create something ..
    end

    def put(env)
    .. replace something ..
    end

    def patch(env)
    .. modify something ..
    end
end
```

## Filters

Before and after filters are evaluated before and after each request within the same context as the routes. They can modify the request and response.

Important note: This should not be used by plugins/addons, instead they should do all their work in their own middleware.

Before you define a `before_all` and `after_all` filter, you must have at least one `HttpConsumer`.

```ruby
before_all "*" do |env|
  puts "Before all was triggered."
end

after_all "*" do |env|
  puts "After all was triggered."
end
```

## Response Codes

The response codes are made up of both upper and lower case symbols which are the RFC representations of the HTTP status codes,
ability to use the numeric representation directly is also available but not recommended, since it is less clear to some people.

```ruby
:OK, :ok #=> 200
:CREATED, :created #=> 201
:ACCEPTED, :accepted #=> 202
:NO_CONTENT, :no_content #=> 204
:MOVED_PERMANENTLY, :moved_permanently #=> 301
:FOUND, :found #=> 302
:SEE_OTHER, :see_other #=> 303
:NOT_MODIFIED, :not_modified #=> 304
:TEMPORARY_REDIRECT, :temporary_redirect #=> 307
:BAD_REQUEST, :bad_request #=> 400
:UNAUTHORIZED, :unauthorized #=> 401
:FORBIDDEN, :forbidden #=> 403
:NOT_FOUND, :not_found #=> 404
:METHOD_NOT_ALLOWED, :method_not_allowed #=> 405
:NOT_ACCEPTABLE, :not_acceptable #=> 406
:PRECONDITION_FAILED, :precondition_failed #=> 412
:IM_A_TEAPOT, :im_a_teapot #=> 418
:INTERNAL_SERVER_ERROR, :internal_server_error #=> 500
:NOT_IMPLEMENTED, :not_implemented #=> 501
```

These symbols can be used with the response tuple:

```ruby
{:ok, {"result" => "Hello, World!"}} #=> 
    # env.response.status_code = 200
    # env.response.print({"result" => "Hello, World!"}.to_json)
```

## Custom Errors

Grip comes with a pre-defined error handlers for the JSON response type. You can customize the built-in error pages or even add your own with `error`.

```ruby
error 404 do
  "This is a customized 404 page."
end

error 403 do
  "Access Forbidden!"
end
```

# HTTP Parameters

When passing data through an HTTP request, you will often need to use query parameters, or post parameters depending on which HTTP method you’re using.

## URL Parameters

Grip allows you to use variables in your route path as placeholders for passing data. To access URL parameters, you use `url?`.

```ruby
class Users < Grip::HttpConsumer
    route "/users/:id", ["GET", "POST"]

    def get(env)
        id = url?(env)["id"]
        {:ok, id}
    end

    def post(env)
        id = url?(env)["id"]
        {:ok, id}
    end
end
```

## Query Parameters

To access query parameters, you use `query?`.

```ruby
class Resize < Grip::HttpConsumer
    route "/resize", ["GET"]

    def get(env)
        width = query?(env)["width"]
        height = query?(env)["height"]
        {:ok, {"image_resolution": "#{width}X#{height}"}}
    end
end
```

## JSON Parameters

You can easily access JSON payload from the parameters, or through the standard post body.

```ruby
class SignIn < Grip::HttpConsumer
    route "/signin", ["POST"]

    def post(env)
        username = json?(env)["username"]
        password = json?(env)["password"]
        
        {:ok, {"username" => username, "password" => password}}
    end
end
```

# HTTP Request / Response Context

The `env` parameter is of `HTTP::Server::Context` type and contains the request and response of the route.

You can easily change the properties of a response, dig in the [Crystal Documentation](https://crystal-lang.org/api/0.20.1/HTTP/Server/Context.html) to find out more.

Request Properties

Some common request information is available at env.request.*:

    method - the HTTP method
        e.g. GET, POST, …
    headers - a hash containing relevant request header information
    body - the request body
    version - the HTTP version
        e.g. HTTP/1.1
    path - the uri path
        e.g. http://kemalcr.com/docs/context?lang=cr => /docs/context
    resource - the uri path and query parameters
        e.g. http://kemalcr.com/docs/context?lang=cr => /docs/context?lang=cr
    cookies
        e.g. env.request.cookies["cookie_name"].value


# Helper Functions

Headers helper function allows you to set custom headers for a specific route response.
```ruby
headers(env, "Host", "github.com")
headers(env, 
        {
          "X-Custom-Header" => "This is a custom value",
          "X-Custom-Header-Two" => "This is a custom value"
        }
)
```

# WebSockets

Using WebSockets in Grip is pretty easy.

An example echo server might look something like this:
```ruby
class Echo < Grip::WebSocketConsumer
  route "/"

  def on_message(env, message)
    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end
```

Accessing headers of the initial HTTP request can be done via a `headers?` method:

```ruby
class Echo < Grip::WebSocketConsumer
  route "/"

  def on_message(env, message)
    puts headers?(env) # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end
```

Dynamic URL parameters can be accessed via a `url?` method:

```ruby
class Echo < Grip::WebSocketConsumer
  route "/:id"

  def on_message(env, message)
    puts url?(env) # This gets the hash instance of the route url specified variables

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end
```

# SSL

Grip has built-in and easy to use SSL support.

To start your Grip with SSL support.

```bash
crystal build --release src/your_app.cr
./your_app --ssl --ssl-key-file your_key_file --ssl-cert-file your_cert_file
```

# Deployment

## Heroku

You can use [heroku-buildpack-crystal](https://github.com/crystal-lang/heroku-buildpack-crystal) to deploy your Grip application to Heroku.

## Cross Compilation

You can cross-compile a Grip app by using this [guide](http://crystal-lang.org/docs/syntax_and_semantics/cross-compilation.html).

# Environment

Grip respects the `GRIP_ENV` environment variable and `Grip.config.env`. It is set to `development` by default.

To change this value to `production`, for example, use:
```bash
$ export KEMAL_ENV=production
```
If you prefer to do this from within your application, use:

```ruby
Grip.config.env = "production"
```
