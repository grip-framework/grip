module Grip
  module Routers
    class Http
      include HTTP::Handler

      CACHED_ROUTES_LIMIT = 1024
      property routes : Radix::Tree(Route)
      property cached_routes : Hash(String, Radix::Result(Route))

      def initialize
        @routes = Radix::Tree(Route).new
        @cached_routes = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        route = lookup_route(
          context.request.method.as(String),
          context.request.path
        )

        raise Exceptions::NotFound.new unless route.found?
        return if context.response.closed?

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, route.params)

        payload = route.payload
        payload.match_via_keyword(context, payload.via)

        if payload.override
          payload.override.not_nil!.call(context)
        else
          payload.handler.call(context)
        end

        # if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(context.response.status_code)
        #   raise ::Exception.new("Routing layer has failed to process the request.")
        # end

        context
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Array(Pipes::Base)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
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
