# Exception

A class which defines a controller for the raised exceptions which might occur during an endpoint execution.

## Code example

```ruby
class Controller < Grip::Controllers::Exception
  def call(context); end
end
```