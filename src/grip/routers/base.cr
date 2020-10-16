module Grip
  module Routers
    abstract class Base
      include HTTP::Handler

      abstract def call(context : HTTP::Server::Context)
      abstract def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Array(Pipes::Base)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
      abstract def lookup_route(verb : String, path : String)
    end
  end
end
