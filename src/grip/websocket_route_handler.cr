module Grip
  class WebSocketRouteHandler
    include HTTP::Handler

    INSTANCE = new
    property routes

    def initialize
      @routes = Radix::Tree(WebSocketRoute).new
    end

    def call(context : HTTP::Server::Context)
      return call_next(context) unless context.ws_route_found? && websocket_upgrade_request?(context)
      content = context.websocket.handler.call(context)
      context.response.print(content)
      context
    end

    def lookup_ws_route(path : String)
      @routes.find "/ws" + path
    end

    def add_route(path : String, handler : Grip::WebSocket)
      add_to_radix_tree path, WebSocketRoute.new(path, handler)
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
