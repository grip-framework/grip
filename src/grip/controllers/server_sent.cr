module Grip
  module Controllers
    module ServerSent
      macro included
        alias Context = ::HTTP::Server::Context
        alias Event = Grip::ServerSent::Event
        alias Strategy = Grip::ServerSent::Strategy
        alias Stream = Grip::ServerSent::Stream

        include ::HTTP::Handler
        include Grip::Helpers::Singleton

        def call(context : Context) : Context
          raise Grip::Exceptions::InternalServerError.new("The execution must never reach the server-side event controller's `call` method")
        end
      end
    end
  end
end
