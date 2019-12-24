require "grip"

class Echo < Grip::WebSocket
  route("/:id")

  def on_message(env, message)
    puts url?(env) # This gets the hash instance of the route url specified variables
    puts headers?(env) # This gets the http headers

    if message == "close"
      close("Closing the connection because of '#{message}'") # This closes the connection
    end

    send(message)
  end

  def on_close(env, message)
    puts message
  end
end

add_handlers [Echo]

Grip.run

