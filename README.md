
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework.

# Super Simple ⚡️

```ruby
require "grip"

class IndexHandler < Grip::Handler
  # Only match the route / and methods defined below
  route("/", ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"])

  def get(env)
    # This gets called when the route receives a GET request
    return call_next(env) unless route_match?(env)

    # Render the content, the default content type is JSON
    render(env, 200, "Hello, GET!")
  end

  def post(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, POST!")
  end

  def put(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, PUT!")
  end

  def patch(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, PATCH!")
  end

  def delete(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, DELETE!")
  end

  def options(env)
    return call_next(env) unless route_match?(env)
    render(env, 200, "Hello, OPTIONS!")
  end
end

class DocumentationHandler < Grip::Handler
  route("/docs", ["GET"])

  def get(env)
    return call_next(env) unless route_match?(env)

    # Render the content as html
    render(env, 200, "<p>Hello, Documentation!</p>", "text/html")
  end
end

# Initialize the handlers
index = IndexHandler.new
docs = DocumentationHandler.new

# Add the handlers to the handler list
add_handlers [index, docs]

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



## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal)
