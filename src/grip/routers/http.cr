module Grip
  module Routers
    class Http < Base
      CACHE_LIMIT = 1024
      property routes : Radix::Tree(Route)
      property cache : Hash(String, Radix::Result(Route))

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        return context if context.response.closed?

        forward = find_route(
          "ALL",
          context.request.path
        )

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, forward.params)

        if forward.found?
          payload = forward.payload
          payload.handler.call(context)

          return context
        end

        route = find_route(
          context.request.method.as(String),
          context.request.path
        )

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, route.params)

        if route.found?
          payload = route.payload
          if payload.override
            payload.call_into_override(context)
          else
            payload.handler.call(context)
          end

          return context
        end

        raise Exceptions::NotFound.new if !route.found? && !forward.found?
        context
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Symbol? | Array(Symbol)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?) : Void
        add_to_radix_tree(method, path, Route.new(method, path, handler, via, override))
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
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
