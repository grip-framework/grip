module Grip
  module Controllers
    abstract class Filter < Base
      abstract def call(context)
    end
  end
end
