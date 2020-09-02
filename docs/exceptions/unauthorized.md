# Internal server error

An exception class which inerits the `Base` of the exception, it represents the `401` error code.

## Code example
```ruby
class Controller < Grip::Controllers::Http
  def get(context)
    raise Grip::Exceptions::Unauthorized.new
  end
end
```