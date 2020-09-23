module Grip
  # Stores all the configuration options for a Grip application.
  # It's a singleton and you can access it like.
  #
  # ```
  # Grip.config
  # ```
  class Config
    INSTANCE        = Config.new
    HANDLERS        = [] of HTTP::Handler
    CUSTOM_HANDLERS = [] of Tuple(Nil | Int32, HTTP::Handler)
    FILTER_HANDLERS = [] of HTTP::Handler
    ERROR_HANDLERS  = {} of Int32 => Grip::Controllers::Exception

    {% if flag?(:without_openssl) %}
      @ssl : Bool?
    {% else %}
      @ssl : OpenSSL::SSL::Context::Server?
    {% end %}

    property host_binding, ssl, port, env, running, logging
    property always_rescue, server : HTTP::Server?, extra_options

    def initialize
      @host_binding = "0.0.0.0"
      @port = 5000
      @logging = true
      @env = ENV["APP_ENV"]? || "development"
      @error_handler = nil
      @always_rescue = true
      @router_included = false
      @default_handlers_setup = false
      @running = false
      @handler_position = 0
    end

    # Returns the current application environment.
    def env
      @env
    end

    # Sets the router for the current application.
    def router=(router)
      @router = router
    end

    # Returns an array of `HTTP::Handler` registered in the configuration class.
    def handlers
      HANDLERS
    end

    # Returns the scheme of the request if the SSL is configured it returns
    # `https`, otherwise it returns `http`
    def scheme
      ssl ? "https" : "http"
    end

    # Clears out the entire configuration file.
    def clear
      @router_included = false
      @handler_position = 0
      @default_handlers_setup = false
      HANDLERS.clear
      CUSTOM_HANDLERS.clear
      FILTER_HANDLERS.clear
      ERROR_HANDLERS.clear
    end

    # Returns an array of `HTTP::Handler` which were registered by the end user.
    def custom_handlers
      CUSTOM_HANDLERS
    end

    # Adds a `HTTP::Handler` to the `CUSTOM_HANDLERS` array.
    def add_handler(handler : HTTP::Handler)
      CUSTOM_HANDLERS << {nil, handler}
    end

    # Adds a `HTTP::Handler` to the `CUSTOM_HANDLERS` array with a defined position.
    def add_handler(handler : HTTP::Handler, position : Int32)
      CUSTOM_HANDLERS << {position, handler}
    end

    # Adds a `HTTP::Handler` to the `FILTER_HANDLERS` array.
    def add_filter_handler(handler : HTTP::Handler)
      FILTER_HANDLERS << handler
    end

    # Adds a `HTTP::Handler` to the `ERROR_HANDLERS` array.
    def error_handlers
      ERROR_HANDLERS
    end

    # Adds an error handler which is a simple block of an expression.
    def add_error_handler(status_code : Int32, resource : Grip::Controllers::Exception)
      ERROR_HANDLERS[status_code] = resource
    end

    # Gathers up extra options from the `OptionParser`.
    def extra_options(&@extra_options : OptionParser ->)
    end

    # Sets up the configuration file.
    def setup
      unless @default_handlers_setup && @router_included
        setup_log_handler
        setup_error_handler
        setup_custom_handlers
        setup_filter_handlers

        @default_handlers_setup = true
        @router_included = true
        HANDLERS.insert(HANDLERS.size, Grip::Routers::WebSocket::INSTANCE)
        HANDLERS.insert(HANDLERS.size, Grip::Routers::Http::INSTANCE)
      end
    end

    private def setup_log_handler
      if @logging
        HANDLERS.insert(@handler_position, Grip::Handlers::Log.new)
        @handler_position += 1
      end
    end

    private def setup_error_handler
      if @always_rescue
        @error_handler ||= Grip::Handlers::Exception.new
        HANDLERS.insert(@handler_position, @error_handler.not_nil!)
        @handler_position += 1
      end
    end

    private def setup_custom_handlers
      CUSTOM_HANDLERS.each do |ch0, ch1|
        position = ch0
        HANDLERS.insert (position || @handler_position), ch1
        @handler_position += 1
      end
    end

    private def setup_filter_handlers
      FILTER_HANDLERS.each do |h|
        HANDLERS.insert(@handler_position, h)
      end
    end
  end

  def self.config
    yield Config::INSTANCE
  end

  def self.config
    Config::INSTANCE
  end
end
