
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework based on JSON request/response model.

Currently Grip is headed towards a JSON request/response type interface, which makes this framework non-HTML friendly, 
it is still possible to render HTML but it is not advised to use Grip for that purpose.

So far at **93657** requests/second per instance, and still going.

![Travis-CI](https://travis-ci.com/grkek/grip.svg?branch=master)

# Super Simple ⚡️

```ruby
require "grip"

class Index < Grip::HttpConsumer
  # Only match the route / and methods defined below
  route "/", ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]

  def get(env)
    # Render the content, the default content type is JSON
    {:ok, {"body": "Hello, GET!"}}
  end

  def post(env)
    {201, {"body": "Hello, POST!"}}
  end

  def put(env)
    {:INTERNAL_SERVER_ERROR, {"body": "Hello, PUT!"}}
  end

  def patch(env)
    {:created, {"body": "Hello, PATCH!"}}
  end

  def delete(env)
    {:CREATED, {"body": "Hello, DELETE!"}}
  end

  def options(env)
    {:ok, {"body": "Hello, OPTIONS!"}}
  end
end

class Indexed < Grip::HttpConsumer
  route "/:id", ["GET"]

  def get(env)
    puts json?(env) # Get the JSON parameters which are sent to the server
    puts query?(env) # Get the query parameters which are sent to the server
    puts url?(env) # Get the url specified parameters like the :id which are sent to the server
    puts headers?(env) # Get the headers which are sent to the server

    # Set headers via two different methods
    headers(env, "Host", "github.com")
    headers(env, {"X-Custom-Header" => "This is a custom value", "X-Custom-Header-Two" => "This is a custom value"})
    
    {:ok, {"body": "Hello, #{url?(env)["id"]}!"}}
  end
end

class Echo < Grip::WebSocketConsumer
  route "/:id" # The routing is based on the kemal router which supports the same routing powers.

  def on_message(env, message)
    puts url?(env) # This gets the hash instance of the route url specified variables
    puts headers?(env) # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!" # This closes the connection
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end

# Add the handlers to the handler list
add_handlers [Index, Indexed, Echo]

# Run the server
Grip.run
```

The default port of the application is `3000`, 
you can set it by either compiling it and providing a `-p` flag or
by changing it from the source code.

Start your application!

If you want logging to show up in the stdout put this line right above the `Grip.run` in your source code.

```ruby
logging true # Keep in mind that logging slows down the server since it is an IO bound operation
```

# Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  grip:
    github: grkek/grip
```

# Features

- Support all REST verbs
- Websocket support
- Request/Response context, easy parameter handling
- Middleware support
- Built-in JSON support

# Documentation

- The documentation currently is not hosted anywhere, yet.

## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal).

Thanks to the official [gitter chat](https://gitter.im/crystal-lang/crystal#) of the Crystal programming language.
