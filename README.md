
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework based on a JSON request/response model with a CRUDish look.

Currently Grip is headed towards a JSON request/response type interface, which makes this framework non-HTML friendly, 
it is still possible to render HTML but it is not advised to use Grip for that purpose.

So far at **158,762** requests/second, and still [going](https://github.com/the-benchmarker/web-frameworks).

[![Build Status](https://travis-ci.org/grkek/grip.svg?branch=master)](https://travis-ci.org/grkek/grip)

# Super Simple ⚡️

```ruby
require "grip"
require "uuid" # Needed for the random UUID generation

class IndexHttpConsumer < Grip::HttpConsumer
  def create(req)
    res(
      HTTP::Status::OK, # The status code is a mix of a built-in and an integer.
      {
        "id": "#{UUID.random}"
      }
    )
  end

  def read(req)
    # By default the response code is 200, this format of content conversion is okay since it gets converted to json by the router.
    {
      "id": "#{UUID.random}"
    }
  end

  def update(req)
    res(
      HTTP::Status::OK,
      {
        "id": "#{UUID.random}"
      }
    )
  end

  def delete(req)
    res(
      HTTP::Status::OK,
      {
        "id": "#{UUID.random}"
      }
    )
  end
end

class IndexedHttpConsumer < Grip::HttpConsumer
  def read(req)
    res(
      HTTP::Status::OK,
      "Hello, World!"
    )
  end
end

class EchoWebSocketConsumer < Grip::WebSocketConsumer
  def on_message(req, message)
    puts url # This gets the hash instance of the route url specified variables
    puts headers # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!" # This closes the connection
    end

    send message
  end

  def on_close(req, message)
    puts message
  end
end

# This gets executed before * (all) routes, the scope can be changed to a specific route
before_all "*" do |req|
  req.response.headers.merge!({"btag" => UUID.random.to_s})
end

# This gets executed after * (all) routes, the scope can be changed to a specific route
after_all "*" do |req|
  req.response.headers.merge!({"atag" => UUID.random.to_s})
end

# Add the handlers to the handler list

add_handlers(
  {
    # Http consumers
    IndexHttpConsumer => "/",
    IndexedHttpConsumer => "/:id",

    # WebSocket consumers
    EchoWebSocketConsumer => "/:id"
  }
)

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

- For the framework development just use the `crystal docs` feature and browse through the module.
- Check out the official documentation available [here](https://github.com/grkek/grip/blob/master/DOCUMENTATION.md)

## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal).

Thanks to the official [gitter chat](https://gitter.im/crystal-lang/crystal#) of the Crystal programming language.
