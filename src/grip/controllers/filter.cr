module Grip
  module Controllers
    abstract class Filter < Base
      abstract def call(context : Context) : Context
    end
  end
end
