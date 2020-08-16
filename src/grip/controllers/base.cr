module Grip
  module Controllers
    abstract class Base
      include HTTP::Handler
      include Grip::DSL::Macros
      include Grip::DSL::Methods

      abstract def call(context : HTTP::Server::Context)
    end
  end
end
