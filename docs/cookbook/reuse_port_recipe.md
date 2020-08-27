# Using reuse port for multiple Grip processes

```ruby
require "grip"

class Application < Grip::Application; end

app = Application.new

System.cpu_count.times do |_|
  Process.fork do
    app.run do |config|
      server = config.server.not_nil!
      server.bind_tcp "0.0.0.0", 3001, reuse_port: true
    end
  end
end
```
