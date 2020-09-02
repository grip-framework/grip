# Hello, World!

```ruby
require "grip"

class IndexController < Grip::Controllers::Http
  def get(context)
    context
      .text("Hello, World!")
  end
end

class Application < Grip::Application
  def initialize
    get "/", IndexController
  end
end

app = Application.new
app.run
```