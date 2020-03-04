module Grip
  module Router
    class WebSocket
      include HTTP::Handler

      INSTANCE = new
      property routes

      def initialize
        @routes = Radix::Tree(Route).new
      end

      def call(context : HTTP::Server::Context)
        return call_next(context) unless context.ws_route_found? && websocket_upgrade_request?(context)

        if context.websocket.via
          Grip::Core::Pipeline::INSTANCE.pipeline[context.websocket.via].each do |pipe|
            pipe.call(context)
          end
        end

        content = context.websocket.handler.call(context)
        context.response.print(content)
        context
      end

      def lookup_ws_route(path : String)
        @routes.find "/ws" + path
      end

      def add_route(path : String, handler : Grip::Controller::WebSocket, via : Symbol?, override)
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
