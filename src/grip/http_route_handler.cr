require "radix"
require "json"

module Grip
  class HttpRouteHandler
    include HTTP::Handler

    INSTANCE            = new
    CACHED_ROUTES_LIMIT = 1024
    property routes, cached_routes

    def initialize
      @routes = Radix::Tree(HttpRoute).new
      @cached_routes = Hash(String, Radix::Result(HttpRoute)).new
    end

    def call(context : HTTP::Server::Context)
      process_request(context)
    end

    # Adds a given route to routing tree. As an exception each `GET` route additionaly defines
    # a corresponding `HEAD` route.
    def add_route(method : String, path : String, handler : Grip::BaseConsumer)
      add_to_radix_tree(method, path, HttpRoute.new(method, path, handler))
    end

    # Looks up the route from the Radix::Tree for the first time and caches to improve performance.
    def lookup_route(verb : String, path : String)
      lookup_path = radix_path(verb, path)

      if cached_route = @cached_routes[lookup_path]?
        return cached_route
      end

      route = @routes.find(lookup_path)

      if route.found?
        @cached_routes.clear if @cached_routes.size == CACHED_ROUTES_LIMIT
        @cached_routes[lookup_path] = route
      end

      route
    end

    # Processes the route if it's a match. Otherwise renders 404.
    private def process_request(context)
      raise Grip::Exceptions::RouteNotFound.new(context) unless context.route_found?
      return if context.response.closed?
      response = context.route.handler.call(context)
      if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(context.response.status_code)
        raise Grip::Exceptions::CustomException.new(context)
      end
      if !response.is_a?(Bool | HTTP::Server::Context | UInt64 | Nil)
        response_hash = response.as(Hash)
        context.response.status_code = response_hash["status"].as(HTTP::Status | Int32).to_i
        if context.response.headers["Content-Type"] == "application/json"
          context.response.print(response_hash["content"].to_json)
        else
          context.response.print(response_hash["content"])
        end
      else
        context.response.print(response)
      end
      context
    end

    private def radix_path(method, path)
      '/' + method.downcase + path
    end

    private def add_to_radix_tree(method, path, route)
      node = radix_path method, path
      @routes.add node, route
    end
  end
end
