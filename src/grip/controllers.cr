module Grip
  # `Grip::Controllers` contains the building classes of `Base`, `Http`, `WebSocket`.
  #
  # These classes provide a basic way of handling incomming requests from the router,
  # they have an easy to use interface and with the use of encapsulation the project becomes
  # a lot cleaner and easier to maintain.
  #
  # An example `Grip::Controllers::Base` class inheritor.
  # Contains a basic `HTTP::Handler#call` function which modifies the context
  # and returns it or passes it on to the next handler.
  #
  # ```
  # class Example < Grip::Controllers::Base
  #   def call(context)
  #   end
  # end 
  # ```
  #
  # An example `Grip::Controllers::Http` class inheritor.
  # Contains 8-9 verbs of the `HTTP` protocol currently the request
  # has already been passed through the `Grip::Controllers::Base#call` and reached the 
  # `Grip::Controllers::Http#get` function, It simply changes the 
  # context and returns it, since there is no `HTTP::Handler#next`,
  # execution stops at the verb endpoint of this class.
  #
  # ```
  # class Example < Grip::Controllers::Http
  #   def get(context)
  #   end
  # end
  # ```
  #
  # An example `Grip::Controllers::WebSocket` class inheritor.
  # Contains `Grip::Controllers::WebSocket#on_open`, `Grip::Controllers::WebSocket#on_ping`,
  # `Grip::Controllers::WebSocket#on_pong`, `Grip::Controllers::WebSocket#on_message`,
  # `Grip::Controllers::WebSocket#on_binary`, `Grip::Controllers::WebSocket#on_close` functions.
  # These functions are triggered when a certain conditions are met, for example the `Grip::Controllers::WebSocket#on_open`  
  # function is executed when the endpoint is faced with a client.
  # 
  # ```
  # class Example < Grip::Controllers::WebSocket
  #   def on_open(context, socket)
  #   end
  # end
  # ```
  module Controllers; end
end