<p align="center" width="100%">
    <img src="https://github.com/grip-framework/medias/blob/master/framework.svg" height="250" href="https://github.com/grip-framework/grip">
</p>

<p align="center">
    The microframework for writing <ins>powerful web applications</ins>.<br><br>
</p>

<p align="center">
  <a href="https://github.com/grip-framework/grip/actions"><img alt="Actions Status" src="https://img.shields.io/github/workflow/status/grip-framework/grip/Crystal%20CI?label=actions&style=flat-square"></a>
</p>

<p align="center">
    <a href="https://www.techempower.com/benchmarks/#section=data-r19&hw=ph&test=plaintext&l=zdk8an-1r"><img alt="TechEmpower Benchmark" src="https://img.shields.io/badge/benchmark-1%2C663%2C946-brightgreen?style=flat-square"></a>
</p>

<p align="center">
  <a href="https://grip-framework.github.io/docs/"><img alt="Docs CI Status" src="https://img.shields.io/github/workflow/status/grip-framework/docs/ci?label=docs&style=flat-square"></a>
</p>

<p align="center">
    <a href="https://gitter.im/grip-framework/grip?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge"><img alt="Chat on Gitter" src="https://img.shields.io/gitter/room/grip-framework/grip?style=flat-square"></a>
</p>

Grip is a microframework for building RESTful web applications. It is designed to be modular and easy to use, with the ability to scale up to the limits of the Crystal programming language. It offers extensibility and has integrated middleware called "pipes". Pipes can alter parts of the request/response context and then get passed to the actual endpoint. Grip's router is very similar to the router of the [Phoenix framework](https://github.com/phoenixframework/phoenix). And most of all: Grip is fast.

## Motivation

This project exists due to the fact that Kemal lacks one crucial part of a framework, a structure. An example for the absence of a structure can be found [here](https://github.com/iv-org/invidious/blob/master/src/invidious.cr).

## Features

- HTTP 1.1 support.
- WebSocket RFC 6455 support.
- Built-in exceptions support.
- Parameter handling support.
- JSON serialization and deserialization support (fastest framework with JSON).
- Built-in third-party module support.
- Request/Response context, inspired by [expressjs](https://github.com/expressjs/express).
- Advanced routing support.

## Code example

Add this to your application's `application.cr`:

```ruby
require "grip"


class IndexController < Grip::Controllers::Http
  def get(context : Context) : Context
    context
      .put_status(200) # Assign the status code to 200 OK.
      .json({"id" => 1}) # Respond with JSON content.
      .halt # Close the connection.
  end

  def index(context : Context) : Context
    id =
      context
        .fetch_path_params
        .["id"]

    # An optional secondary argument gives a custom `Content-Type` header to the response.
    context
      .json(content: {"id" => id}, content_type: "application/json; charset=us-ascii")
      .halt
  end

  def error(context : Context) : Context
    if context.request.path.includes?("/api/error")
      raise ArgumentError.new("An example message.")
    end

    context
      .json({"id" => UUID.random.to_s})
      .halt
  end
end

class ExceptionController < Grip::Controllers::Exception
  def call(context : Context) : Context
    context
      .json({"error" => context.exception.try(&.message)}) # The exception is nilable.
      .halt
  end
end

class Swigger::Swagger < HTTP::Handler
  def call(context : Context) : Context
    context.html("<h1>Hello, World!</h1>")
  end
end

class Application < Grip::Application
  def initialize(environment : String, serve_static : Bool)
    # By default the environment is set to "development" and serve_static is false.
    super(environment, serve_static)

    exception ArgumentError, ExceptionController

    scope "/api" do
      get "/error", IndexController, as: :error

      scope "/v1" do
        get "/", IndexController
        get "/:id", IndexController, as: :index
      end
    end

    forward "/swagger/*", Swigger::Swagger

    # Enable request/response logging.
    router.insert(0, Grip::Handlers::Log.new)
  end
end

app = Application.new(environment: "development", serve_static: false)
app.run
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  grip:
    github: grip-framework/grip
    branch: core
```

And run this command in your terminal:

```bash
shards install
```

## API Reference

Documentation can be found on the [official website of the Grip framework](https://grip-framework.github.io/docs/).

## Contribute

See our [contribution guidelines](https://github.com/grip-framework/grip/blob/master/CONTRIBUTING.md) and read the [code of conduct](https://github.com/grip-framework/grip/blob/master/CODE_OF_CONDUCT.md).
