# Base

A class which stores the base functions of a `Grip::Controller`, this should be inherited if a framework extension is an option.

## Code example

```ruby
class Controller < Grip::Controllers::Base
  def call(context); end
end
```