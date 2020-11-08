module Grip
  module Controllers
    abstract class Base
      include HTTP::Handler
      alias Context = HTTP::Server::Context
      alias Parameters = NamedTuple

      abstract def call(context : Context) : Context
    end
  end
end
