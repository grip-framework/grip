module Grip
  # Route is the main building block of Kemal.
  #
  # It takes 3 parameters: http *method*, *path* and a *handler* to specify
  # what action to be done if the route is matched.
  struct HttpRoute
    getter method, path, handler

    def initialize(@method : String, @path : String, @handler : Grip::BaseConsumer)
    end
  end
end
