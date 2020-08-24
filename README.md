[![Grip](https://github.com/grip-framework/medias/blob/master/gripen.svg)](https://github.com/grip-framework/grip)

# Grip
Grip is a microframework for building RESTful web applications. It is designed to be modular and easy to use, with the ability to scale up to the limits of the Crystal programming language. It offers extensibility and it has integrated middleware called "pipes" which alter the parts of the request/response context and pass it on to the actual endpoint. It has a router which somewhat resembles that of [Phoenix framework](https://github.com/phoenixframework/phoenix)'s router and most of all it is fast, peaking at [1,663,946](https://www.techempower.com/benchmarks/#section=data-r19&hw=ph&test=json&l=zdk8an-1r) requests/second for plain text response.

## Motivation
The existance of this project is due to the fact that Kemal lacks one crucial part of every successful framework, a structure. An example for the absence of structure can be found [here](https://github.com/iv-org/invidious/blob/master/src/invidious.cr).

## Build status
[![Build Status](https://travis-ci.org/grip-framework/grip.svg?branch=master)](https://travis-ci.org/grip-framework/grip)
[![Build Status](https://action-badges.now.sh/grip-framework/grip)](https://github.com/grip-framework/grip/actions)

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

class Index < Grip::Controllers::Http
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
    
    context
      .json({"id" => id})
  end
end

class Application < Grip::Application
  def initialize
    pipeline :api, [
        Grip::Pipes::Log.new,
        Grip::Pipes::PoweredByHeader.new,
    ]
    
    get "/", Index, via: :api
    get "/:id", Index, via: :api, override: :index
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
A temporary API reference can be found [here](https://github.com/grip-framework/grip/blob/master/DOCUMENTATION.md), while this document is somewhat complete it is still missing some of the information that could be provided. That is why we are working on creating the wiki page for this repository which will depict the entire framework and deliver the information in great detail.

## Contribute
See our [contribution guidelines](https://github.com/grip-framework/grip/blob/master/CONTRIBUTING.md) and read the [code of conduct](https://github.com/grip-framework/grip/blob/master/CODE_OF_CONDUCT.md).

## Contributors
- [Giorgi Kavrelishvili](https://github.com/grkek) - creator and maintainer.
- [nilsding](https://github.com/nilsding)
- [Whaxion](https://github.com/Whaxion)

## Thanks
- [Kemal](https://github.com/kemalcr/kemal) - Underlying routing, parameter parsing and filtering mechanisms.
- [Gitter](https://gitter.im/crystal-lang/crystal) - Technical help, feedback and framework design tips.
- [Crystal](https://crystal-lang.org/api/0.35.1/) - Detailed documentation, examples.
