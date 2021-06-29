require "../routers/route"

module Grip
  module Handlers
    # :nodoc:
    class Forward
      include HTTP::Handler

      CACHE_LIMIT = 1024
      property routes : Radix::Tree(Grip::Routers::Route)
      property cache : Hash(String, Radix::Result(Grip::Routers::Route))

      def initialize
        @routes = Radix::Tree(Grip::Routers::Route).new
        @cache = Hash(String, Radix::Result(Grip::Routers::Route)).new
      end

      def call(context : HTTP::Server::Context)
        return context if context.response.closed?

        forward = find_route(
          "ALL",
          context.request.path
        )

        route = find_route(
          context.request.method.as(String),
          context.request.path
        )

        if forward.found?
          context.parameters = Grip::Parsers::ParameterBox.new(context.request, forward.params)
          payload = forward.payload

          payload.handler.call(context)

          return context
        end

        return call_next(context) if !route.found? && !forward.found?
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Symbol? | Array(Symbol)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?) : Void
        add_to_radix_tree(method, path, Grip::Routers::Route.new(method, path, handler, via, override))
      end

      def find_route(verb : String, path : String) : Radix::Result(Grip::Routers::Route)
        lookup_path = radix_path(verb, path)

        if cached_route = @cache[lookup_path]?
          return cached_route
        end

        route = @routes.find(lookup_path)

        if route.found?
          @cache.clear if @cache.size == CACHE_LIMIT
          @cache[lookup_path] = route
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
