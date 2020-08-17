module Grip
  module Controllers
    abstract class Exception < Base
      abstract def call(context)
      abstract def call(context, exception, status_code = 400)
    end
  end
end
