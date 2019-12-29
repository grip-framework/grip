
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
    # The direct return renders the content as html
    "<p>Hello, Documentation!</p>"
  end
end

class Indexed < Grip::Http
  route("/:id", ["GET"])

  def get(env)
    puts json?(env) # Get the JSON parameters which are sent to the server
    puts body?(env) # Get the body parameters which are sent to the server
    puts query?(env) # Get the query parameters which are sent to the server
    puts url?(env) # Get the url specified parameters like the :id which are sent to the server
    puts headers?(env) # Get the headers which are sent to the server

    # Set headers via two different methods
    headers(env, "Host", "github.com")
    headers(env, {"X-Custom-Header" => "This is a custom value", "X-Custom-Header-Two" => "This is a custom value"})
    render(env, 200, url?(env)["id"])
  end
end

class Templated < Grip::Http
  route("/:name", ["GET", "POST"])

  def get(env)
    params = url?(env)

    #
    # The template generation stems from Kilt which is a fantastic library,
    # for this example we are going to create a file named index.ecr in the src/views/ directory
    # and then we are including something like this in the index.ecr file:
    #
    # Hello, <%= params["name"] %>
    #
    if params["name"] == "admin"
      render_template(env, 200, "src/views/index.ecr")
    else
      # Redirect the client to /login
      redirect(env, "/login")
    end
  end

  def post(env)
    # This does the same as the function above but without the env and response code parameters.
    render_template("src/views/index.ecr")
  end
end

class Echo < Grip::WebSocket
  route("/:id") # The routing is based on the kemal router which supports the same routing powers.

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
add_handlers [Index, Documentation, Indexed, Templated, Echo]

# Run the server
Grip.run
```

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
- Built-in static file serving
- Built-in view templating via [Kilt](https://github.com/jeromegn/kilt)

# Documentation

- The documentation currently is not hosted anywhere, yet.

## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal)
