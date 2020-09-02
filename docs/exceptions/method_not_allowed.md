# Method not allowed

An exception class which inerits the `Base` of the exception, it represents the `405` error code.

## Code example
```ruby
class Controller < Grip::Controllers::Http
  def get(context)
    raise Grip::Exceptions::MethodNotAllowed.new
  end
end
```