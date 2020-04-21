# Getting Started

This guide assumes that you already have Crystal installed. If not, check out the [Crystal installation methods](https://crystal-lang.org/install/) and come back when you’re done.

Most of the [Kemal](https://kemalcr.com/cookbook/hello_world/) framework parts still work in Grip, which makes porting your source code easy.

## Installing Grip

First you need to create your application:

```bash
$ crystal init app your_app
$ cd your_app
```

Then add _Grip_ to your `shard.yml` file as a dependency.

```yaml
dependencies:
  grip:
    github: grip-framework/grip
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

class Index < Grip::Controller::Http
  # `context` contains the `request` and the `response` of an HTTP connection,
  # the `json` function expands to:
  #
  #   def json(context, content, status_code = HTTP::Status::OK)
  #     context.response.status_code = status_code.to_i 
  #     context.response.headers.merge!({"Content-Type" => "application/json"})
  #     content.to_json
  #   end
  #
  # and it is a "helper" function which helps you by avoiding so much boilerplate.
  #
    
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

class App < Grip::Application
  def initialize
    get "/", Index
  end
end

app = App.new
app.run
```

Keep in mind that the context modifier must return a `String` literal otherwise the router will panic and the application won't compile.

## Running Grip

Starting your application is easy, simply run:

```bash
$ crystal run src/your_app.cr
```

If everything went well you should see no errors and a message which indicates the server address.

# Routing and Response

## Routing

You can route certain consumers to paths using several methods.

Avaliable HTTP verbs are: `GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD`.

### Resource

Resource annotation routes all of the avaliable verbs to appropriate method modifiers,
you can alter the selected methods which must be included or excluded from the resource.

#### Default

```ruby
# Routes requests to appropriate requested method modifiers.
resource "/", Index
```

#### Only

```ruby
# Only routes requests to the `GET` and `POST` modifiers.
resource "/", Index, only: [:get, :post]
```

#### Exclude

```ruby
# Routes requests to appropriate requested method modifiers, except `GET` and `POST` requests.
resource "/", Index, exclude: [:get, :post]
```

### HTTP verbs

All of the modifier verbs are interchangeable, you can combine and use `override` and `via` together.

#### Default

```ruby
# Routes `GET` requests to the appropriate modifier of the Index controller.
get "/", Index
```

#### Via

```ruby
# Routes `GET` requests to the appropriate modifier but before that happens it routes the request through a pipeline,
# which contains several pre-defined middleware native to Grip or handwritten by the user which modifies the request
# and passes it on to the next pipe until it reaches the desired endpoint.
pipeline :web, [
  Grip::Pipe::Log.new
]

get "/", Index, via: :web
```

#### Override

```ruby
# Routes `GET` requests to the `index` modifier of the `Index` controller, instead of using the default `get` modifier
# defined in the controller it uses an `index` modifier which also must be defined in the controller for it to work.
get "/", Index, override: :index
```


## Routes

You can handle HTTP methods via pre-defining a set of available modifiers and then creating separate handlers for each. Each consumer is a separate resource located in a single route, which uses radix trees for additional flexibility.

```ruby
class Index < Grip::Controller::Http
  def get(context)
    .. show something ..
  end

  def post(context)
    .. create something ..
  end

  def put(context)
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

The current filter supports all of the verbs which are RESTful, for example defining a `before_get` filter looks like this:

```
before_get "/" do |context|
  context.response.content_type = "application/json"
end
```

For a more detailed explanation read the [filter section](https://kemalcr.com/guide/#filters) of the Kemal framework.

## Middleware

In Grip middlewares are mentioned as handlers or consumers, when creating a handler or a consumer you inherit from HTTP::Handler or Grip::Controller::Http.

### Raw middleware

Raw middleware is the `HTTP::Handler` class.

```ruby
class CustomHandler
  include HTTP::Handler

  def call(context)

  end
end

# You can add the middleware to the handler stack by using
class App < Grip::Application
  def initialize
    add_handler CustomHandler.new
  end
end

app = App.new
app.run
```

### Pipe middleware

Pipe middleware is the building block of the framework, some helpful pipes are included with the framework. Creating a custom pipe is as easy as creating an HTTP handler.

Advantage of the pipe over a raw middleware is that you can controll what routes go through the middleware and what don't.

```ruby
class Custom < Grip::Pipe::Base
  def call(context)

  end
end

class Index < Grip::Controller::Http
  def get(context)
    json(
      context,
      {
        "message" => "Hello, world!"
      }
    )
  end
end

# You can add the handler just by doing the same as you do to other consumer types.
class App < Grip::Application
  def initialize
    pipeline :web, [
      Custom.new
    ]

    get "/", Index, via: :web
  end
end

app = App.new
app.run
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
class App < Grip::Application
  def initialize
    error 404 do
      "This is a customized 404 page."
    end

    error 403 do
      "Access Forbidden!"
    end
  end
end

app = App.new
app.run
```

# HTTP Parameters

When passing data through an HTTP request, you will often need to use query parameters, or post parameters depending on which HTTP method you’re using.

## URL Parameters

Grip allows you to use variables in your route path as placeholders for passing data. To access URL parameters, you use `url`.

```ruby
class Users < Grip::Controller::Http
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

class App < Grip::Application
  def initialize
    resource "/:id", Users, only: [:get, :post]
  end
end

app = App.new
app.run
```

## Query Parameters

To access query parameters, you use `query`.

```ruby
class Resize < Grip::Controller::Http
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

class App < Grip::Application
  def initialize
    get "/", Resize
  end
end

app = App.new
app.run
```

## JSON Parameters

You can easily access JSON payload from the parameters, or through the standard post body.

```ruby
class SignIn < Grip::Controller::Http
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

class App < Grip::Application
  def initialize
    post "/", SignIn
  end
end

app = App.new
app.run
```

# HTTP Request / Response Context

The `context` parameter is of `HTTP::Server::Context` type and contains the request and response of the route.

You can easily change the properties of a response, dig in the [Crystal Documentation](https://crystal-lang.org/api/0.34.0/HTTP/Server/Context.html) to find out more.

# Helper Functions

Helper functions are defined in: [DSL/Methods](https://github.com/grip-framework/grip/blob/master/src/grip/dsl/methods.cr), [Extensions/Context](https://github.com/grip-framework/grip/blob/master/src/grip/extensions/context.cr). Taking a quick look will help you understand more of the innerworkings of the Grip framework.

# WebSockets

Using WebSockets in Grip is pretty easy.

Keep in mind the `Via` modifier is supported by the websocket verb, which gives you the ability to put additional pipelines on the websocket route.

An example echo server might look something like this:

```ruby
class Echo < Grip::Controller::WebSocket
  def on_open(context, socket)
    puts "An user has connected to the websocket endpoint."  
  end
  
  def on_message(context, socket, message)
    if message == "close"
      close(socket, "Received a 'close' message, closing the connection!")
    end

    socket.send message
  end

  def on_close(context, socket, code, message)
    puts code, message
  end
end

class App < Grip::Application
  def initialize
    ws "/", Echo
  end
end

app = App.new
app.run
```

Accessing headers of the initial HTTP request can be done via a `headers` method:

```ruby
class Echo < Grip::Controller::WebSocket
  def on_message(context, socket, message)
    puts headers(context) # This gets the http headers

    if message == "close"
      close(socket, "Received a 'close' message, closing the connection!")
    end

    socket.send message
  end

  def on_close(context, socket, code, message)
    puts code, message
  end
end

class App < Grip::Application
  def initialize
    ws "/", Echo
  end
end

app = App.new
app.run
```

Dynamic URL parameters can be accessed via a `url` method:

```ruby
class Echo < Grip::Controller::WebSocket
  def on_message(context, socket, message)
    puts ws_url(context) # This gets the hash instance of the route url specified variables

    if message == "close"
      close(socket, "Received a 'close' message, closing the connection!")
    end

    socket.send message
  end

  def on_close(context, socket, code, message)
    puts code, message
  end
end

class App < Grip::Application
  def initialize
    ws "/", Echo
  end
end

app = App.new
app.run
```

# Pipes

Grip has built-in pipeline system which is used for pipeing the connection through a series of middleware.

```ruby
pipeline :web, [
  Grip::Pipe::Log.new,
  Grip::Pipe::PoweredByGrip.new,
]
```

Other than a `Log` and `PoweredByGrip` middleware there is also a

- `Basic` authorization middleware, for basic authorization needs.
- `Jwt` authorization middleware, for JWT authorization needs.
- `SecureHeaders` middleware, for securing and hardening your headers.
- `ClientIp` middleware, for grabbing the ip address of the incomming connection.

Some of the pipes have built-in helper functions, for example the Jwt pipe has `encode_and_sign` and `decode_and_verify` functions which encode and sign the payload and decode and verify the token.

Using authorization middleware requires additional configuration, for example:

```ruby
pipeline :web, [
  Grip::Pipe::Basic.new("username", "password"),
]
```

or even a more advanced authorization scheme:

```ruby
pipeline :web, [
  Grip::Pipe::Jwt.new(
    ENV["JWT_SECRET"], # This is the secret key which is used to decode the content of the token.
    {:aud => "Authorization", :iss => "MyCoolCompany", :sub => nil} # These are the claims for the token, usually the sub is left nil for later re-use purposes.
  ),
]
```

Accessing the decoded payload of the pipe can be done through the `context.assigns` class which contains the properties of all the pipes.

If you want to use the decoded payload from the Jwt pipeline just access the `context.assigns` for example:

```ruby
class Index < Grip::Controller::Http
  def get(context)
    json(
      context,
      {
        "decoded" => context.assigns.jwt,
      }
    )
  end
end
```

You can extend the assigns class, create a pipe which uses the Jwt pipe to automatically grab the resource out of your database by the `sub` claim, now you have got yourself something equivalent of a `Guardian` package for the `Phoenix` framework.

If you want detailed knowledge about the pipes and how they work just peak into the source code and you will understand easily.

# SSL

Grip has built-in and easy to use SSL support.

To start your Grip with SSL support.

```bash
crystal build --release src/your_app.cr
./your_app --ssl --ssl-key-file your_key_file --ssl-cert-file your_cert_file
```

# Testing

[spec-kemal](https://github.com/kemalcr/spec-kemal) has been forked to make testing easy.

Add [_spec-grip_](https://github.com/grip-framework/spec-grip) to your `shard.yml` file as a dependencie.

```yaml
dependencies:
  grip:
    github: grip-framework/grip
  spec-grip:
    github: grip-framework/spec-grip
```

Then run `shards` to get the dependencies:

```bash
$ shards install
```

Now you should require it before your files in your `spec/spec_helper.cr`

```ruby
require "spec-grip"
require "../src/your-grip-app"
```

Your Grip application

```ruby
# src/your-grip-app.cr

require "grip"

class Index < Grip::Controller::Http
  def get(context)
    "Hello, World!"
  end
end

class App < Grip::Application
  def initialize
    get "/", Index
  end
end

app = App.new
app.run
```

Now you can easily test your `Grip` application in your `spec`s.

```
GRIP_ENV=test crystal spec
```

```ruby
# spec/your-grip-app-spec.cr

describe "Your::Grip::App" do
  # You can use get,post,put,patch,delete to call the corresponding route.
  it "renders /" do
    get "/"
    response.body.should eq "Hello, World!"
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
