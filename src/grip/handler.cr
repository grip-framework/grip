require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `only`, `only_match?`, `exclude`, `exclude_match?`.
  # These methods are useful for the conditional execution of custom handlers .
  class Handler
    include HTTP::Handler

    @@routes_tree = Radix::Tree(String).new

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
        @@routes_tree.add class_name_method + {{path}}, '/' + method_downcase + {{path}}
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

    # Processes the path based on `only` paths which is a `Array(String)`.
    # If the path is not found on `only` conditions the handler will continue processing.
    # If the path is found in `only` conditions it'll stop processing and will pass the request
    # to next handler.
    #
    # However this is not done automatically. All handlers must inherit from `Kemal::Handler`.
    #
    # ```
    # class OnlyHandler < Kemal::Handler
    #   only ["/"]
    #
    #   def call(env)
    #     return call_next(env) unless only_match?(env)
    #     puts "If the path is / i will be doing some processing here."
    #   end
    # end
    # ```
    def route_match?(env : HTTP::Server::Context)
      @@routes_tree.find(radix_path(env.request.method, env.request.path)).found?
    end

    private def radix_path(method : String, path : String)
      "#{self.class}/#{method.downcase}#{path}"
    end
  end
end