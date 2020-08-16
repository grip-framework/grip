module Grip
  module Router
    class WebSocket
      include HTTP::Handler

      INSTANCE            = new
      CACHED_ROUTES_LIMIT = 1024
      property routes, cached_routes

      def initialize
        @routes = Radix::Tree(Route).new
        @cached_routes = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        return call_next(context) unless context.ws_route_found? && websocket_upgrade_request?(context)

        if context.websocket.via
          Grip::Core::Pipeline::INSTANCE.pipeline[context.websocket.via].each do |pipe|
            pipe.call(context)
          end
        end

        context.websocket.handler.call(context)
      end

      def lookup_ws_route(path : String)
        lookup_path = "/ws" + path

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

      def add_route(path : String, handler : Grip::Controllers::WebSocket, via : Symbol?, override)
        add_to_radix_tree path, Route.new("", path, handler, via, nil)
      end

      private def add_to_radix_tree(path, websocket)
        node = radix_path "ws", path
        @routes.add node, websocket
      end

      private def radix_path(method, path)
        '/' + method.downcase + path
      end

      private def websocket_upgrade_request?(context)
        return unless upgrade = context.request.headers["Upgrade"]?
        return unless upgrade.compare("websocket", case_insensitive: true) == 0

        context.request.headers.includes_word?("Connection", "Upgrade")
      end
    end
  end
end
