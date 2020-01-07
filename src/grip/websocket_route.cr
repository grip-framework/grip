module Grip
  struct WebSocketRoute
    getter path, handler

    def initialize(@path : String, @handler : Grip::WebSocketConsumer)
    end
  end
end
