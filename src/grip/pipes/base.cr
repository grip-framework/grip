module Grip
  module Pipes
    abstract class Base
      include HTTP::Handler

      abstract def call(context : HTTP::Server::Context)
    end
  end
end
