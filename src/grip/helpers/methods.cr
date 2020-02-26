module Grip::Helpers::Methods
  def json(context : HTTP::Server::Context)
    context.params.json
  end

  def query(context : HTTP::Server::Context)
    context.params.query
  end

  def url(context : HTTP::Server::Context)
    context.params.url
  end

  def ws_url(context : HTTP::Server::Context)
    context.ws_route_lookup.params
  end

  def headers(context : HTTP::Server::Context)
    context.request.headers
  end

  def add_handler(handler : HTTP::Handler)
    Grip.config.add_handler handler
  end

  def add_handler(handler : HTTP::Handler, position : Int32)
    Grip.config.add_handler handler, position
  end

  def log(message : String)
    Grip.config.logger.write "#{message}\n"
  end

  def logging(status : Bool)
    Grip.config.logging = status
  end

  def logger(logger : Grip::BaseLogHandler)
    Grip.config.logger = logger
    Grip.config.add_handler logger
  end
end
