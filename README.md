
[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grkek/grip)

# Grip

Class oriented fork of the [Kemal](https://kemalcr.com) framework based on a JSON request/response model.

Currently Grip is headed towards a JSON request/response type interface, which makes this framework non-HTML friendly, 
it is still possible to render HTML but it is not advised to use Grip for that purpose.

So far at **158,762** requests/second, and still [going](https://github.com/the-benchmarker/web-frameworks).

[![Build Status](https://travis-ci.org/grkek/grip.svg?branch=master)](https://travis-ci.org/grkek/grip)

# Super Simple ⚡️

```ruby
require "grip"
require "uuid" # Needed for the random UUID generation

class Index < Grip::HttpConsumer
  def get(env)
    {
      "status" => HTTP::Status::CONTINUE, # HTTP::Status is an enum which has all of the response codes.
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end

  def post(env)
    {
      "status": 200, # Alternative to HTTP::Status you can use integers directly as response codes.
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end

  def put(env)
    {
      "status" => HTTP::Status::MULTIPLE_CHOICES,
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end

  def patch(env)
    {
      "status" => 400,
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end

  def delete(env)
    {
      "status" => HTTP::Status::INTERNAL_SERVER_ERROR,
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end

  def options(env)
    {
      "status" => 418,
      "content" => {
        "Bunch of content gathered up in one place"
      }
    }
  end
end

class Indexed < Grip::HttpConsumer
  def get(env)
    puts json(env) # Get the JSON parameters which are sent to the server
    puts query(env) # Get the query parameters which are sent to the server
    puts url(env) # Get the url specified parameters like the :id which are sent to the server
    puts headers(env) # Get the headers which are sent to the server
    
    # Set custom headers using this function
    headers(env, 
            {
              "X-Custom-Header" => "This is a custom value",
              "X-Custom-Header-Two" => "This is a custom value"
            }
    )

    {
      "status" => 200,
      "content" => {
        url(env)
      }
    }
  end
end

class Echo < Grip::WebSocketConsumer
  def on_message(env, message)
    puts url(env) # This gets the hash instance of the route url specified variables
    puts headers(env) # This gets the http headers

    if message == "close"
      close "Received a 'close' message, closing the connection!" # This closes the connection
    end

    send message
  end

  def on_close(env, message)
    puts message
  end
end

# This gets executed before * (all) routes, the scope can be changed to a specific route
before_all "*" do |env|
  env.response.headers.merge!({"btag" => UUID.random.to_s})
end

# This gets executed after * (all) routes, the scope can be changed to a specific route
after_all "*" do |env|
  env.response.headers.merge!({"atag" => UUID.random.to_s})
end

# Add the handlers to the handler list

add_handlers(
  {
    Index => "/",
    Indexed => "/:id",

    Echo => "/:id"
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
