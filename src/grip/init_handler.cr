module Grip
  # Initializes the context with default values, such as
  # *Content-Type* or *server* headers.
  class InitHandler
    include HTTP::Handler

    INSTANCE = new

    def call(context : HTTP::Server::Context)
      context.response.headers.add "server", "grip" if Grip.config.powered_by_header
      context.response.content_type = "application/json" unless context.response.headers.has_key?("Content-Type")
      call_next context
    end
  end
end
