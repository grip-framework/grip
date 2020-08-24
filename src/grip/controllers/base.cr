module Grip
  module Controllers
    abstract class Base
      include HTTP::Handler

      abstract def call(context : HTTP::Server::Context)
    end
  end
end
