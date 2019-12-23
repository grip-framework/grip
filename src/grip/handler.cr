require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class Handler
    include HTTP::Handler

    @@handler_path = String.new
    @@handler_methods = Array(String).new

    def initialize
      @@handler_methods.each do |method|
        Grip::RouteHandler::INSTANCE.add_route(method.upcase, @@handler_path, self)
      end
    end

    def to_s(io)
      if @@handler_methods.size > 1
        io << "Route registered at '" << @@handler_path << "' and is reachable via '" << @@handler_methods << "' methods."
      else
        io << "Route registered at '" << @@handler_path << "' and is reachable via a '" << @@handler_methods[0] << "' method."
      end
    end

    macro route(path, methods = ["GET"])
      @@handler_path = {{path}}
      {{methods}}.each do |method|
        @@handler_methods.push(method)
      end
    end

    macro render(env, status_code = 200, response = "", content_type = "application/json")
      {{env}}.response.status_code = {{status_code}}
      {{env}}.response.content_type = {{content_type}}
      {% if content_type != "application/json" %}
        {{env}}.response.print({{response}})
      {% else %}
        {{env}}.response.print({{response}}.to_json())
      {% end %}
      {{env}}.response.close()
    end

    macro halt(env, status_code = 404, response = "", content_type = "application/json")
      {{env}}.response.status_code = {{status_code}}
      {{env}}.response.content_type = {{content_type}}
      {% if content_type != "application/json" %}
        {{env}}.response.print({{response}})
      {% else %}
        {{env}}.response.print({{response}}.to_json())
      {% end %}
      {{env}}.response.close()
    end

    # get post put patch delete options
    def get(env : HTTP::Server::Context)
      call_next(env)
    end

    def post(env : HTTP::Server::Context)
      call_next(env)
    end

    def put(env : HTTP::Server::Context)
      call_next(env)
    end

    def patch(env : HTTP::Server::Context)
      call_next(env)
    end

    def delete(env : HTTP::Server::Context)
      call_next(env)
    end

    def options(env : HTTP::Server::Context)
      call_next(env)
    end

    def call(env : HTTP::Server::Context)
      case env.request.method
      when "GET"
        get(env)
      when "POST"
        post(env)
      when "PUT"
        put(env)
      when "PATCH"
        patch(env)
      when "DELETE"
        delete(env)
      when "OPTIONS"
        options(env)
      else
        call_next(env)
      end
    end

    def json?(env : HTTP::Server::Context)
      env.params.json
    end

    def body?(env : HTTP::Server::Context)
      env.params.body
    end

    def query?(env : HTTP::Server::Context)
      env.params.query
    end

    def url?(env : HTTP::Server::Context)
      env.params.url
    end
  end
end
