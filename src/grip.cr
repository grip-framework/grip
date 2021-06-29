require "http"
require "http/web_socket"
require "json"
require "uri"
require "radix"
require "base64"
require "uuid"
require "crypto/subtle"
require "exception_page"
require "swagger"

{% if flag?(:with_openssl) %}
  require "openssl/sha1"
{% else %}
  require "digest/sha1"
{% end %}

require "./grip/annotations/**"
require "./grip/exceptions/base"
require "./grip/exceptions/*"
require "./grip/support/*"
require "./grip/minuscule/*"
require "./grip/parsers/*"
require "./grip/dsl/*"
require "./grip/extensions/*"
require "./grip/handlers/*"
require "./grip/controllers/*"
require "./grip/routers/route"
require "./grip/routers/*"
require "./grip/*"

module Grip; end

class Authorization < Grip::Controllers::Base
  def initialize(@username : String, @password : String); end

  def call(context : Context) : Context
    context
      .put_status(201)
      .json({username: @username, password: @password})
      .halt
  end
end

class ProtectedController < Grip::Controllers::Http
  def get(context)
    context
      .put_status(200)
      .json({status: 200, message: "You are accessing a protected resource"})
      .halt
  end
end

class Application < Grip::Application
  def routes
    # Forward macro simply routes the matched requests to a certain Base controller
    # which contains a single call/1 function.
    forward "/", Authorization, username: "admin", password: "admin"
    get "/:id", ProtectedController
  end
end

app = Application.new
app.run
