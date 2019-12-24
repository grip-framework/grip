
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework.

# Super Simple ⚡️

```ruby
require "grip"

class Index < Grip::Http
  # Only match the route / and methods defined below
  route("/", ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"])

  def get(env)
    # Render the content, the default content type is JSON
    render(env, 200, "Hello, GET!")
  end

  def post(env)
    render(env, 200, "Hello, POST!")
  end

  def put(env)
    render(env, 200, "Hello, PUT!")
  end

  def patch(env)
    render(env, 200, "Hello, PATCH!")
  end

  def delete(env)
    render(env, 200, "Hello, DELETE!")
  end

  def options(env)
    render(env, 200, "Hello, OPTIONS!")
  end
end

class Documentation < Grip::Http
  route("/docs", ["GET"])

  def get(env)
    # Render the content as html
    render(env, 200, "<p>Hello, Documentation!</p>", "text/html")
  end
end

class Indexed < Grip::Handler
  route("/:id", ["GET"])

  def get(env)
    puts json?(env) # Get the JSON parameters which are sent to the server
    puts body?(env) # Get the body parameters which are sent to the server
    puts query?(env) # Get the query parameters which are sent to the server
    puts url?(env) # Get the url specified parameters like the :id which are sent to the server
    puts headers?(env) # Get the headers which are sent to the server

    # Set headers
    headers(env, "Host", "github.com")
    render(env, 200, url?(env)["id"])
  end
end

class Echo < Grip::WebSocket
  route("/:id") # Either this or route("/") this, it depends what you want to achieve with it

  def on_message(env, message)
    puts url?(env) # This gets the hash instance of the route url specified variables
    puts headers?(env) # This gets the http headers

    if message == "close"
      close("Received a 'close' message, closing the connection!") # This closes the connection
    end

    send(message)
  end

  def on_close(env, message)
    puts message
  end
end

# Add the handlers to the handler list
add_handlers [IndexHandler, DocumentationHandler, IndexedHandler, Echo]

# Run the server
Grip.run
```

Start your application!

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
- Built-in static file serving
- Built-in view templating via [Kilt](https://github.com/jeromegn/kilt)

# Documentation

- The documentation currently is not hosted anywhere, yet.

## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal)
