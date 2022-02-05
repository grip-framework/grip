module Grip
  module Controllers
    abstract class Base
      alias Context = HTTP::Server::Context

      abstract def call(context : Context) : Context
    end
  end
end
