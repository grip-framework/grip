module Grip
  module Controllers
    abstract class Filter < Base
      abstract def call(context : HTTP::Server::Context)
    end
  end
end
