[![Grip](https://avatars0.githubusercontent.com/u/44188195?s=200&v=4)](https://github.com/grip-framework/grip)

# Grip

Grip is a microframework for building RESTful web applications. It is designed to be modular and easy, with the ability to scale up. It began as a fork of the [Kemal](https://kemalcr.com) framework and has become one of the most interesting frameworks of the Crystal programming language.

Grip offers extensibility, it has integrated middleware called "pipes" which alter the parts of the request/response context and pass it on to the actual endpoint. It has a router which somewhat resembles that of [Phoenix framework](https://github.com/phoenixframework/phoenix)'s router and most of all it is fast, peaking at [285,013](https://github.com/the-benchmarker/web-frameworks) requests/second.

[![Build Status](https://travis-ci.org/grip-framework/grip.svg?branch=master)](https://travis-ci.org/grip-framework/grip)
[![Gitter](https://img.shields.io/gitter/room/grip-framework/grip)](https://gitter.im/grip-framework/community)

# Super Simple ⚡️

```ruby
require "grip"

class Index < Grip::Controller::Http
  def get(context)
    json(
      context,
      {
        "id" => 1,
      }
    )
  end
end

class Application < Grip::Application
  def initialize
    get "/", Index
  end
end

app = Application.new
app.run
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
- Check out the official documentation available [here](https://github.com/grip-framework/grip/blob/master/DOCUMENTATION.md)

## Thanks

Thanks to Manas for their awesome work on [Frank](https://github.com/manastech/frank).

Thanks to Serdar for the awesome work on [Kemal](https://github.com/kemalcr/kemal).

Thanks to the official [gitter chat](https://gitter.im/crystal-lang/crystal#) of the Crystal programming language.
