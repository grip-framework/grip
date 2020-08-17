module Grip
  module Controllers
    abstract class Exception
      include Grip::DSL::Methods
      abstract def call(context, exception, status_code = 400)
    end
  end
end