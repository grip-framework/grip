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
require "uuid" # For random UUID generation.

class IndexHttpConsumer < Grip::HttpConsumer
    # The status and content of a response are mandatory, without it the router wont function.
    # The status value is precieved as the response code,
    # and the content value is precieved as the response content.
    def get(context)
      # HTTP::Status is an enum which has all of the response codes alternatively you can use an integer.
      json(
        context,
        {
          "id": "#{UUID.random}"
        }
      )
    end
end

class IdApi < Grip::Application
  def initialize
    resource "/", IndexHttpConsumer
  end
end

id_api = IdApi.new
id_api.run
```

## Running Grip

Starting your application is easy, simply run:

```bash
$ crystal run src/your_app.cr
```

If everything went well you should see 0 errors.

# Routing and Response

## Routing
You can route certain consumers to paths using several methods.

Supported verbs are:
- `resource` - Resource which defines all the verbs.
- `get` - GET verb.
- `post` - POST verb.
- `put` - PUT verb.
- `patch` - PATCH verb.
- `delete` - DELETE verb.
- `options` - OPTIONS verb.
- `head` - HEAD verb.

```ruby
resource "/", IndexHttpConsumer #=> Routes requests to request methods.
resource "/", IndexHttpConsumer, only: [:get, :post] #=> Routes requests 'GET' and 'POST' to methods `get` and `post`.
resource "/", IndexHttpConsumer, exclude: [:get, :post] #=> Routes requests to request methods, except the `get` and the `post`.

get "/", IndexHttpConsumer #=> Routes the GET request to the consumer `get` method.
get "/", IndexHttpConsumer, :index #=> Routes GET request to the consumer `index` method.
```



## Routes
You can handle HTTP methods via pre-defining a set of available methods and then creating separate handlers for each. Each consumer is a separate resource located a single route, which uses radix trees for additional flexibility.

```ruby
class IndexHttpConsumer < Grip::HttpConsumer
    def create(context)
    .. create something ..
    end

    def read(context)
    .. show something ..
    end

    def update(context)
    .. update something ..
    end

    def delete(context)
    .. delete something ..
    end
end
```

## Filters

Before and after filters are evaluated before and after each request within the same context as the routes. They can modify the request and response.

Important note: This should not be used by plugins/addons, instead they should do all their work in their own middleware.

Before you define a `before_all` and `after_all` filter, you must have at least one `HttpConsumer`.

```ruby
before_all "*" do |context|
  puts "Before all was triggered."
end

after_all "*" do |context|
  puts "After all was triggered."
end
```

## Middleware
In Grip middlewares are mentioned as handlers or consumers, when creating a handler or a consumer you inherit from HTTP::Handler or Grip::HttpConsumer.

### Raw middleware

Raw middleware is the `HTTP::Handler` class.

```ruby
class CustomHandler
  include HTTP::Handler

  def call(context)

  end
end

# You can add the middleware to the handler stack by using
class IdApi < Grip::Application
  def initialize
    add_handler CustomHandler.new
  end
end

id_api = IdApi.new
id_api.run
```


### Vanilla middleware

Vanilla middleware contains several helpful functions which differentiate the `BaseConsumer` class from the raw `HTTP::Handler` class.

```ruby
class CustomConsumer < Grip::HttpConsumer
  def call(context)
    # You can use the call_next and match? functions to control the flow of the middleware stack,
    # if it matches the route defined above it will execute the content below otherwise it calls the call_next function.
    return call_next(context) unless match?(context)
    html(
      context,
      "Some custom middleware processing was done here !"
    )
  end
end

# You can add the handler just by doing the same as you do to other consumer types.
class IdApi < Grip::Application
  def initialize
    resource "/", CustomBaseConsumer
  end
end

id_api = IdApi.new
id_api.run
```

## Response Codes

The response codes are borrowed from HTTP::Status enum which contains all of the response codes, alternative to that is to use integers directly.

```ruby
# Enum based status code
json(
  context,
  "Wonderful JSON content.",
  HTTP::Status::OK
)

# Integer based status code
html(
  context,
  "Wonderful JSON content.",
  200
)

# Default is 200 OK
text(
  context,
  "Wonderful JSON content."
)
```

## Custom Errors

Grip comes with a pre-defined error handlers for the JSON response type. You can customize the built-in error pages or even add your own with `error`.

```ruby
class IdApi < Grip::Application
  def initialize
    error 404 do
      "This is a customized 404 page."
    end

    error 403 do
      "Access Forbidden!"
    end
  end
end

id_api = IdApi.new
id_api.run
```

# HTTP Parameters

When passing data through an HTTP request, you will often need to use query parameters, or post parameters depending on which HTTP method you’re using.

## URL Parameters

Grip allows you to use variables in your route path as placeholders for passing data. To access URL parameters, you use `url`.

```ruby
class UsersHttpConsumer < Grip::HttpConsumer
    def get(context)
      params = url(context)
      json(
        context,
        {
          "id": params["id"]
        }
      )
    end

    def post(context)
      params = url(context)
      json(
        context,
        {
          "id": params["id"]
        }
      )
    end
end

class IdApi < Grip::Application
  def initialize
    resource "/:id", UserHttpConsumer, only: [:get, :post]
  end
end

id_api = IdApi.new
id_api.run
```

## Query Parameters

To access query parameters, you use `query`.

```ruby
class ResizeHttpConsumer < Grip::HttpConsumer
  def get(context)
    params = query(context)
    width = params["width"]
    height = params["height"]

    json(
      context,
      {
        "imageResolution": {
          "width": width,
          "height": height
        }
      }
    )
  end
end

class IdApi < Grip::Application
  def initialize
    get "/", ResizeHttpConsumer
  end
end

id_api = IdApi.new
id_api.run
```

## JSON Parameters

You can easily access JSON payload from the parameters, or through the standard post body.

```ruby
class SignInHttpConsumer < Grip::HttpConsumer
  def create(context)
    params = json(context)
    username = params["username"]
    password = params["password"]

    json(
      context,
      {
        "authorizationInformation": {
          "username": username,
          "password": password
        }
      }
    )
  end
end

class IdApi < Grip::Application
  def initialize
    post "/", SignInHttpConsumer
  end
end

id_api = IdApi.new
id_api.run
```

# HTTP Request / Response Context

The `context` parameter is of `HTTP::Server::Context` type and contains the request and response of the route.

You can easily change the properties of a response, dig in the [Crystal Documentation](https://crystal-lang.org/api/0.20.1/HTTP/Server/Context.html) to find out more.

Request Properties

Some common request information is available at context.request.*:

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
        e.g. context.request.cookies["cookie_name"].value


# Helper Functions

Headers helper function allows you to set custom headers for a specific route response.
```ruby
headers(
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
class EchoWebSocketConsumer < Grip::WebSocketConsumer
  def on_message(context, message)
    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(context, message)
    puts message
  end
end

class IdApi < Grip::Application
  def initialize
    ws "/", EchoWebSocketConsumer
  end
end

id_api = IdApi.new
id_api.run
```

Accessing headers of the initial HTTP request can be done via a `headers` method:

```ruby
class EchoWebSocketConsumer < Grip::WebSocketConsumer
  def on_message(context, message)
    puts headers(context) # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(context, message)
    puts message
  end
end

class IdApi < Grip::Application
  def initialize
    ws "/", EchoWebSocketConsumer
  end
end

id_api = IdApi.new
id_api.run
```

Dynamic URL parameters can be accessed via a `url` method:

```ruby
class EchoWebSocketConsumer < Grip::WebSocketConsumer
  def on_message(context, message)
    puts ws_url(context) # This gets the hash instance of the route url specified variables

    if message == "close"
      close "Received a 'close' message, closing the connection!"
    end

    send message
  end

  def on_close(context, message)
    puts message
  end
end

class IdApi < Grip::Application
  def initialize
    ws "/", EchoWebSocketConsumer
  end
end

id_api = IdApi.new
id_api.run
```

# SSL

Grip has built-in and easy to use SSL support.

To start your Grip with SSL support.

```bash
crystal build --release src/your_app.cr
./your_app --ssl --ssl-key-file your_key_file --ssl-cert-file your_cert_file
```

# Testing

[spec-kemal](https://github.com/kemalcr/spec-kemal) has been forked to make testing easy.

Add [*spec-grip*](https://github.com/Whaxion/spec-grip) to your `shard.yml` file as a dependencie.

```yaml
dependencies:
    grip:
        github: grkek/grip
    spec-grip:
        github: Whaxion/spec-grip
```

Then run `shards` to get the dependencies:

```bash
$ shards install
```

Now you should require it before your files in your `spec/spec_helper.cr`

```crystal
require "spec-grip"
require "../src/your-grip-app"
```

Your Grip application

```crystal
# src/your-grip-app.cr

require "grip"

class HelloWorldHttpConsumer < Grip::HttpConsumer
  def get(context)
    "Hello world"
  end
end

class HelloWorld < Grip::Application
  def initialize
    get "/", HelloWorldHttpConsumer
  end
end

HelloWorld.new.run
```

Now you can easily test your `Grip` application in your `spec`s.

```
GRIP_ENV=test crystal spec
```

```crystal
# spec/your-grip-app-spec.cr

describe "Your::Grip::App" do

  # You can use get,post,put,patch,delete to call the corresponding route.
  it "renders /" do
    get "/"
    response.body.should eq "Hello World!"
  end

end
```

# Deployment

## Heroku

You can use [heroku-buildpack-crystal](https://github.com/crystal-lang/heroku-buildpack-crystal) to deploy your Grip application to Heroku.

## Cross Compilation

You can cross-compile a Grip app by using this [guide](http://crystal-lang.org/docs/syntax_and_semantics/cross-compilation.html).

# environment

Grip respects the `GRIP_ENV` environment variable and `Grip.config.env`. It is set to `development` by default.

To change this value to `production`, for example, use:
```bash
$ export GRIP_ENV=production
```
If you prefer to do this from within your application, use:

```ruby
Grip.config.env = "production"
```
