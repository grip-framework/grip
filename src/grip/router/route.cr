module Grip
  module Router
    struct Route
      getter method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controller::Base, @via : Symbol?, @override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
      end
    end
  end
end
