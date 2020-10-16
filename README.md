<p align="center" width="100%">
    <img src="https://github.com/grip-framework/medias/blob/master/framework.svg" height="250" href="https://github.com/grip-framework/grip">
</p>

<p align="center">
    The microframework for writing <ins>powerful web applications</ins>.<br><br>
    <b>Notice:</br>Versions bellow 2.0.0 are not maintained anymore.
</p>

<p align="center">
  <a href="https://travis-ci.org/grip-framework/grip"><img alt="Travis Status" src="https://img.shields.io/travis/grip-framework/grip?label=travis&style=flat-square"></a>
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

It is designed to be modular and easy to use, with the ability to scale up to the limits of the Crystal programming language. It offers extensibility and it has integrated middleware called "pipes" which alter the parts of the request/response context and pass it on to the actual endpoint. It has a router which somewhat resembles that of [Phoenix framework](https://github.com/phoenixframework/phoenix)'s router and most of all it is fast.

## Motivation

The existance of this project is due to the fact that Kemal lacks one crucial part of every successful framework, a structure. An example for the absence of structure can be found [here](https://github.com/iv-org/invidious/blob/master/src/invidious.cr).

## Features

- HTTP 1.1 support.
- WebSocket RFC 6455 support.
- Built-in exceptions support.
- Parameter handling support.
- JSON serialization and deserialization support.
- Built-in middleware support.
- Request/Response context, inspired by [expressjs](https://github.com/expressjs/express).
- Advanced routing support.

## Code example

Add this to your application's `application.cr`:

```ruby
require "grip"

class IndexController < Grip::Controllers::Http
  def get(context)
    context
      .put_status(200) # Assign the status code to 200 OK.
      .json({"id" => 1}) # Respond with JSON content.
      .halt # Close the connection.
  end

  def index(context)
    id =
      context
        .fetch_path_params
        .["id"]

    # An optional secondary argument gives a custom `Content-Type` header to the response.
    context
      .json({"id" => id}, "application/json; charset=us-ascii")
  end
end

class Application < Grip::Application
  def routes
    pipeline :api, [
        Pipes::PoweredByHeader.new
    ]

    pipeline :web, [
        Pipes::SecureHeaders.new
    ]

    get "/", IndexController, via: :api
    get "/:id", IndexController, via: [:web, :api], override: :index
  end
end

app = Application.new
app.run
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  grip:
    github: grip-framework/grip
```

And run this command in your terminal:

```bash
shards install
```

## API Reference

Documentation can be found on the [official website of the Grip framework](https://grip-framework.github.io/docs/).

## Contribute

See our [contribution guidelines](https://github.com/grip-framework/grip/blob/master/CONTRIBUTING.md) and read the [code of conduct](https://github.com/grip-framework/grip/blob/master/CODE_OF_CONDUCT.md).

## Contributors

- [Giorgi Kavrelishvili](https://github.com/grkek) - creator and maintainer.
- [nilsding](https://github.com/nilsding) - contributor
- [Whaxion](https://github.com/Whaxion) - contributor
- [Vincent Agnano](https://github.com/vinyll) - contributor

## Thanks

- [Kemal](https://github.com/kemalcr/kemal) - Underlying routing, parameter parsing and filtering mechanisms.
- [Gitter](https://gitter.im/crystal-lang/crystal) - Technical help, feedback and framework design tips.
- [Crystal](https://crystal-lang.org/api/0.35.1/) - Detailed documentation, examples.
