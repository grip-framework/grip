module Grip
  module Routers
    class Http
      include HTTP::Handler

      INSTANCE            = new
      CACHED_ROUTES_LIMIT = 1024
      property routes, cached_routes

      def initialize
        @routes = Radix::Tree(Route).new
        @cached_routes = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        raise Grip::Exceptions::NotFound.new(context) unless context.route_found?
        return if context.response.closed?

        context.route.match_via_keyword(context, context.route.via)

        if context.route.override
          context.route.override.not_nil!.call(context)
        else
          context.route.handler.call(context)
        end

        if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(context.response.status_code)
          raise ::Exception.new("Routing layer has failed to process the request.")
        end

        context
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Symbol?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
        add_to_radix_tree(method, path, Route.new(method, path, handler, via, override))
      end

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

      private def radix_path(method, path)
        '/' + method.downcase + path
      end

      private def add_to_radix_tree(method, path, route)
        node = radix_path method, path
        @routes.add node, route
      end
    end
  end
end
