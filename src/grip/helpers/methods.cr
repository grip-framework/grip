module Grip::Helpers::Methods
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

  def gzip(status : Bool = false)
    add_handler HTTP::CompressHandler.new if status
  end
end
