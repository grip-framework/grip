require "./singleton"

module Grip
  module Controllers
    abstract class Exception < Base
      include Singleton

      abstract def call(context : Context) : Context
    end
  end
end
