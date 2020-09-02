# Internal server error

An exception class which inerits the `Base` of the exception, it represents the `500` error code.

## Code example
```ruby
class Controller < Grip::Controllers::Http
  def get(context)
    raise Grip::Exceptions::InternalServerError.new
  end
end
```