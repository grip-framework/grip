module Grip
  module Routers
    abstract class Base
      include HTTP::Handler

      abstract def call(context : HTTP::Server::Context)
      abstract def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Symbol? | Array(Symbol)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?) : Void
      abstract def find_route(verb : String, path : String) : Radix::Result(Route)
    end
  end
end
