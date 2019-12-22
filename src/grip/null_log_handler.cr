module Grip
  # This is here to represent the logger corresponding to Null Object Pattern.
  class NullLogHandler < Grip::BaseLogHandler
    def call(context : HTTP::Server::Context)
      call_next(context)
    end

    def write(message : String)
    end
  end
end
