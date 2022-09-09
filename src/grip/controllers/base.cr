module Grip
  module Controllers
    abstract class Base
      include Helpers::Singleton
      alias Context = HTTP::Server::Context

      abstract def call(context : Context) : Context
    end
  end
end
