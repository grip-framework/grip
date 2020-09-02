# Filter

A class which defines a controller for a filter middleware, anything which doesn't pass the logic defined in the call function will return.

## Code example

```ruby
class Controller < Grip::Controllers::Filter
  def call(context); end
end
```