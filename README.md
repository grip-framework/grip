
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework based on a JSON request/response model.

Currently Grip is headed towards a JSON request/response type interface, which makes this framework non-HTML friendly, 
it is still possible to render HTML but it is not advised to use Grip for that purpose.

So far at **285,013** requests/second, and still [going](https://github.com/the-benchmarker/web-frameworks).

[![Build Status](https://travis-ci.org/grip-framework/grip.svg?branch=master)](https://travis-ci.org/grip-framework/grip)

# Super Simple ⚡️

```ruby
require "grip"

class Index < Grip::Controller::Http
  def get(context)
    # The status code is a mix of a built-in and an integer,
    # By default every res has a 200 OK status response.
    json(
      context,
      {
        "id" => 1
      },
      200
    )
  end

  def create(context)
    puts url(context) # This gets the hash instance of the route url specified variables
    puts query(context) # This gets the query parameters passed in with the url
    puts json(context) # This gets the JSON data which was passed into the route
    puts headers(context) # This gets the http headers
    
    params = url(context)

    json(
      context,
      {
        "id" => params["id"]
      },
      HTTP::Status::OK
    )
  end
end

class Echo < Grip::Controller::WebSocket
  def on_message(context, message)
    send message
  end
end

# Routing
class IdApi < Grip::Application
  def initialize
    pipeline :web, [
      Grip::Pipe::Log.new,
      Grip::Pipe::ClientIp.new,
      Grip::Pipe::PoweredByGrip.new
    ]

    get "/", Index
    post "/:id", Index, via: :web, override: :create
    ws "/:id", Echo, via: :web
  end
end

# Run the server
id_api = IdApi.new
id_api.run
```

The default port of the application is `3000`, 
you can set it by either compiling it and providing a `-p` flag or
by changing it from the source code.

Start your application!

# Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  grip:
    github: grip-framework/grip
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
