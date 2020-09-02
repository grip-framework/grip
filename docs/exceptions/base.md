# Base

An exeption class which defines the base of a `Grip` exception.

## Code example
```ruby
class Exception < Grip::Exceptions::Base
  def initialize
    @status = HTTP::Status::IM_A_TEAPOT
    super "I am a teapot, hello!"
  end
end
```