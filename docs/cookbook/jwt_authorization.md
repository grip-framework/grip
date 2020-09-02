# JWT Authorization

Make sure you have set the `JWT_SECRET` env key.

```ruby
require "grip"

class Context
  struct Assigns
    property ip : String?
    property basic : String?
    property jwt : JSON::Any?

    # We extend the Assigns struct with this.
    property current_user : String?
  end
end

class UserController < Grip::Controllers::Http
  def sign_in(context)
    username =
      context
        .fetch_json_params
        .["username"]
        .to_s
      
    password =
      context
        .fetch_json_params
        .["password"]
        .to_s

    if username == "admin" && password == "admin"
      token = Grip::Pipes::Jwt.encode_and_sign(
        {
          "username" => username,
          "password" => password
        }
      )

      context
        .json(
          {
            "token" => token
          }
        )
    else
      raise Grip::Exceptions::BadRequest.new
    end
  end

  def get(context)
    context
      .json(
        {
          "id" => 1,
          "email" => "protected_information@email.com"
        }
      )
  end
end

class CurrentUser < Grip::Pipes::Base
  def call(context)
    context.assigns.current_user = context.assigns.jwt.not_nil!.["username"].to_s
  end
end

class Application < Grip::Application
  def initialize
    pipeline :web, [
      Grip::Pipes::Log.new,
      Grip::Pipes::PoweredByHeader.new
    ]

    pipeline :authorization, [
      Grip::Pipes::Jwt.new,
      CurrentUser.new
    ]

    get "/", UserController, via: [:web, :authorization]
    post "/", UserController, via: [:web], override: :sign_in
  end
end

app = Application.new
app.run
```