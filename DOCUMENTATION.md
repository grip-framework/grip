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
    # The status and content of a response are mandatory, without it the router wont function.
    # The status value is precieved as the response code,
    # and the content value is precieved as the response content.
    def get(env)
      {
        # HTTP::Status is an enum which has all of the response codes alternatively you can use an integer.
        "status" => HTTP::Status::OK,
        "content" => {
          "Bunch of content gathered up in one place"
        }
      }
    end
end

add_handlers(
  {
    Index => "/"
  }
)

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

## Middleware
In Grip middlewares are mentioned as handlers or consumers, when creating a handler or a consumer you inherit from HTTP::Handler or Grip::BaseConsumer.

### Raw middleware

Raw middleware is the `HTTP::Handler` class.

```ruby
class CustomHandler
  include HTTP::Handler

  def call(context)

  end
end

# You can add the middleware to the handler stack by using
add_handler CustomHandler.new
```


### Vanilla middleware

Vanilla middleware contains several helpful functions which differentiate the `BaseConsumer` class from the raw `HTTP::Handler` class.

```ruby
class CustomConsumer < Grip::BaseConsumer
  def initialize(handler_path)
    @@handler_path = handler_path
    # You have to add the consumer somehow to the router, it is done by the initialize function,
    # you can create your own custom router which can work fine but at this moment
    # the default HttpRouteHandler and WebsocketRouteHandler are recommended.
    @@handler_methods.each do |method|
      Grip::HttpRouteHandler::INSTANCE.add_route(method.upcase, @@handler_path, self)
    end
  end

  def call(env)
    # You can use the call_next and match? functions to control the flow of the middleware stack,
    # if it matches the route defined above it will execute the content below otherwise it calls the call_next function.
    return call_next(env) unless match?(env)
    {
      "status" => HTTP::Status::OK,
      "content" => "Some custom middleware processing was done here"
    }
  end
end

# You can add the handler just by doing the same as you do to other consumer types.
add_handlers(
  {
    CustomConsumer => "/"
  }
)
```

## Response Codes

The response codes are borrowed from HTTP::Status enum which contains all of the response codes, alternative to that is to use integers directly.

```ruby
# Enum based status code
{
  "status" => HTTP::Status::OK,
  "content" => {
    "Bunch of content gathered up in one place"
  }
}

# Integer based status code
{
  "status" => 200,
  "content" => {
    "Bunch of content gathered up in one place"
  }
}
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

Grip allows you to use variables in your route path as placeholders for passing data. To access URL parameters, you use `url`.

```ruby
class Users < Grip::HttpConsumer
    def get(env)
      id = url["id"]
      {
        "status" => 200,
        "content" => id
      }
    end

    def post(env)
      id = url["id"]
      {
        "status" => 200,
        "content" => id
      }
    end
end

add_handlers(
  {
    Users => "/users/:id"
  }
)
```

## Query Parameters

To access query parameters, you use `query`.

```ruby
class Resize < Grip::HttpConsumer
  def get(env)
    width = query["width"]
    height = query["height"]

    {
      "status" => HTTP::Status::OK,
      "content" => {
        "imageResolution": {
          "width": width,
          "height": height
        }
      }
    }
  end
end

add_handlers(
  {
    Resize => "/users/:id"
  }
)
```

## JSON Parameters

You can easily access JSON payload from the parameters, or through the standard post body.

```ruby
class SignIn < Grip::HttpConsumer
  def post(env)
    username = json["username"]
    password = json["password"]
        
    {
      "status" => HTTP::Status::OK,
      "content" => {
        "authorizationInformation": {
          "username": username,
          "password": password
        }
      }
    }
  end
end

add_handlers(
  {
    SignIn => "/signin"
  }
)
```

# HTTP Request / Response Context

The `env` parameter is of `HTTP::Server::Context` type and contains the request and response of the route.

You can easily change the properties of a response, dig in the [Crystal Documentation](https://crystal-lang.org/api/0.20.1/HTTP/Server/Context.html) to find out more.

Request Properties

Some common request information is available at env.request.*:

  - method - the HTTP method
        e.g. GET, POST, …
  - headers - a hash containing relevant request header information
  - body - the request body
  - version - the HTTP version
        e.g. HTTP/1.1
  - path - the uri path
        e.g. http://kemalcr.com/docs/context?lang=cr => /docs/context
  - resource - the uri path and query parameters
        e.g. http://kemalcr.com/docs/context?lang=cr => /docs/context?lang=cr
  - cookies
        e.g. env.request.cookies["cookie_name"].value


# Helper Functions

Headers helper function allows you to set custom headers for a specific route response.
```ruby
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

add_handlers(
  {
    Echo => "/"
  }
)
```

Accessing headers of the initial HTTP request can be done via a `headers` method:

```ruby
class Echo < Grip::WebSocketConsumer
  def on_message(env, message)
    puts headers # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end

add_handlers(
  {
    Echo => "/"
  }
)
```

Dynamic URL parameters can be accessed via a `url` method:

```ruby
class Echo < Grip::WebSocketConsumer
  def on_message(env, message)
    puts url # This gets the hash instance of the route url specified variables

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end

add_handlers(
  {
    Echo => "/:id"
  }
)
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
