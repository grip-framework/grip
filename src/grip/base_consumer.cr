module Grip
  abstract class BaseConsumer
    include HTTP::Handler

    abstract def call(env : HTTP::Server::Context)
  end
end
