# Filter

A class which defines a controller for a WebSocket endpoint.

## Code example

```ruby
class Controller < Grip::Controllers::Http
  def on_open(context, socket); end
  def on_ping(context, socket, _); end
  def on_pong(context, socket, _); end
  def on_message(context, socket, message); end
  def on_binary(context, socket, binary); end
  def on_close(context, socket, error_code, error_message); end
end
```