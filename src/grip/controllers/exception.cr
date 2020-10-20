module Grip
  module Controllers
    abstract class Exception < Base
      abstract def call(context : Context) : Context
    end
  end
end
