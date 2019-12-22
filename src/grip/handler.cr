require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class Handler
    include HTTP::Handler

    @@routes = Radix::Tree(String).new
    @@handler_path = String.new
    @@handler_methods = Array(String).new

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
        class_name = {{@type.name}}
        method_downcase = method.downcase
        class_name_method = "#{class_name}/#{method_downcase}"
        @@routes.add class_name_method + {{path}}, '/' + method_downcase + {{path}}
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

    def route_match?(env : HTTP::Server::Context)
      @@routes.find(radix_path(env.request.method, env.request.path)).found?
    end

    def json?(env : HTTP::Server::Context)
      if !env.params.json.nil?
        env.params.json
      end
    end

    def body?(env : HTTP::Server::Context)
      if !env.params.body.nil?
        env.params.body
      end
    end

    private def radix_path(method : String, path : String)
      "#{self.class}/#{method.downcase}#{path}"
    end
  end
end
