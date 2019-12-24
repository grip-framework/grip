module Grip
  struct WebSocketRoute
    getter path, handler

    def initialize(@path : String, @handler : Grip::WebSocket)
    end
  end
end
