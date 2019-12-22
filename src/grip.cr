require "http"
require "json"
require "uri"
require "./grip/*"
require "./grip/ext/*"
require "./grip/helpers/*"

module Grip
  # Overload of `self.run` with the default startup logging.
  def self.run(port : Int32?, args = ARGV)
    self.run(port, args) { }
  end

  # Overload of `self.run` without port.
  def self.run(args = ARGV)
    self.run(nil, args: args)
  end

  # Overload of `self.run` to allow just a block.
  def self.run(args = ARGV, &block)
    self.run(nil, args: args, &block)
  end

  # The command to run a `Grip` application.
  #
  # If *port* is not given Grip will use `Grip::Config#port`
  #
  # To use custom command line arguments, set args to nil
  #
  def self.run(port : Int32? = nil, args = ARGV, &block)
    Grip::CLI.new args
    config = Grip.config
    config.setup
    config.port = port if port

    # Test environment doesn't need to have signal trap and logging.
    if config.env != "test"
      setup_404
      setup_trap_signal
    end

    server = config.server ||= HTTP::Server.new(config.handlers)

    config.running = true

    yield config

    # Abort if block called `Grip.stop`
    return unless config.running

    unless server.each_address { |_| break true }
      {% if flag?(:without_openssl) %}
        server.bind_tcp(config.host_binding, config.port)
      {% else %}
        if ssl = config.ssl
          server.bind_tls(config.host_binding, config.port, ssl)
        else
          server.bind_tcp(config.host_binding, config.port)
        end
      {% end %}
    end

    display_startup_message(config, server)

    server.listen unless config.env == "test"
  end

  def self.display_startup_message(config, server)
    addresses = server.addresses.map { |address| "#{config.scheme}://#{address}" }.join ", "
    log "[#{config.env}] Grip is listening at #{addresses}"
  end

  def self.stop
    raise "Grip is already stopped." if !config.running
    if server = config.server
      server.close unless server.closed?
      config.running = false
    else
      raise "Grip.config.server is not set. Please use Grip.run to set the server."
    end
  end

  private def self.setup_404
    unless Grip.config.error_handlers.has_key?(404)
      error 404 do
        render_404
      end
    end
  end

  private def self.setup_trap_signal
    Signal::INT.trap do
      Grip.stop
      exit
    end
  end
end
