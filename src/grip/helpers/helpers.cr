require "json"

module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `only`, `only_match?`, `exclude`, `exclude_match?`.
  # These methods are useful for the conditional execution of custom handlers .
  class Handler
    include HTTP::Handler

    @@only_routes_tree = Radix::Tree(String).new

    @@handler_path = String.new
    @@handler_method = String.new

    def to_s(io)
      io << "Route registered at '" << @@handler_path << "' and is reachable via a '" << @@handler_method << "' method."
    end

    macro only(path, method = "GET")
      @@handler_path = {{path}}
      @@handler_method = {{method}}

      class_name = {{@type.name}}
      method_downcase = {{method}}.downcase
      class_name_method = "#{class_name}/#{method_downcase}"
      @@only_routes_tree.add class_name_method + {{path}}, '/' + method_downcase + {{path}}
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

    macro halt(env, status_code = 200, response = "", content_type = "application/json")
      {{env}}.response.status_code = {{status_code}}
      {{env}}.response.content_type = {{content_type}}
      {% if content_type != "application/json" %}
        {{env}}.response.print({{response}})
      {% else %}
        {{env}}.response.print({{response}}.to_json())
      {% end %}
      {{env}}.response.close()
    end
    

    def call(env : HTTP::Server::Context)
      call_next(env)
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
    def only_match?(env : HTTP::Server::Context)
      @@only_routes_tree.find(radix_path(env.request.method, env.request.path)).found?
    end

    private def radix_path(method : String, path : String)
      "#{self.class}/#{method.downcase}#{path}"
    end
  end
end
