# Bad request

An exception class which inerits the `Base` of the exception, it represents the `400` error code.

## Code example
```ruby
class Controller < Grip::Controllers::Http
  def get(context)
    raise Grip::Exceptions::BadRequest.new
  end
end
```