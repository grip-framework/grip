# Application

A class which initializes the crucial parts of the web-framework.

## Code example

```ruby
class Application < Grip::Application
  def initialize
    pipeline :api, [
      Grip::Pipes::PoweredByHeader.new,
    ]
  end
end

app = Application.new
app.run
```
