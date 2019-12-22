require "grip"

ws "/" do |socket|
  socket.send "Hello from Grip!"

  socket.on_message do |message|
    socket.send "Echo back from server #{message}"
  end
end

Grip.run
