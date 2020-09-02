# Macros

A module which defines a set of functions for ease of use.

## Code example

```ruby
class Controller < Grip::Controllers::Http; end

class Application < Grip::Application
  def initialize

    get "/", Controller
    post "/1", Controller
    # ETC.
  end
end
```