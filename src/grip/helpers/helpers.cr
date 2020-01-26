# Adds given `Grip::Handler` to handlers chain.
# There are 5 handlers by default and all the custom handlers
# goes between the first 4 and the last `Grip::RouteHandler`.
#
# - `Grip::InitHandler`
# - `Grip::LogHandler`
# - `Grip::ExceptionHandler`
# - Here goes custom handlers
# - `Grip::RouteHandler`

def add_handler(handler : HTTP::Handler)
  Grip.config.add_handler handler
end

def add_handler(handler : HTTP::Handler, position : Int32)
  Grip.config.add_handler handler, position
end

macro add_handlers(handlers)
  {{handlers}}.each do |handler|
    instance = handler.first.new(handler.last)
    if Grip.config.env == "development"
      puts instance
    end
  end
end

# Logs the output via `logger`.
# This is the built-in `Grip::LogHandler` by default which uses STDOUT.
def log(message : String)
  Grip.config.logger.write "#{message}\n"
end

# Enables / Disables logging.
# This is enabled by default.
#
# ```
# logging false
# ```
def logging(status : Bool)
  Grip.config.logging = status
end

# This is used to replace the built-in `Grip::LogHandler` with a custom logger.
#
# A custom logger must inherit from `Grip::BaseLogHandler` and must implement
# `call(env)`, `write(message)` methods.
#
# ```
# class MyCustomLogger < Grip::BaseLogHandler
#   def call(env)
#     puts "I'm logging some custom stuff here."
#     call_next(env) # => This calls the next handler
#   end
#
#   # This is used from `log` method.
#   def write(message)
#     STDERR.puts message # => Logs the output to STDERR
#   end
# end
# ```
#
# Now that we have a custom logger here's how we use it
#
# ```
# logger MyCustomLogger.new
# ```
def logger(logger : Grip::BaseLogHandler)
  Grip.config.logger = logger
  Grip.config.add_handler logger
end

# Helper for easily modifying response headers.
# This can be used to modify a response header with the given hash.
#
# ```
# def call(env)
#   headers(env, {"X-Custom-Header" => "This is a custom value"})
# end
# ```
def headers(env : HTTP::Server::Context, additional_headers : Hash(String, String))
  env.response.headers.merge!(additional_headers)
end

# Configures an `HTTP::Server::Response` to compress the response
# output, either using gzip or deflate, depending on the `Accept-Encoding` request header.
#
# Disabled by default.
def gzip(status : Bool = false)
  add_handler HTTP::CompressHandler.new if status
end
