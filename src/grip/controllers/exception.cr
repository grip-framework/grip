module Grip
  module Controllers
    abstract class Exception < Base
      abstract def call(context : HTTP::Server::Context)
    end
  end
end
