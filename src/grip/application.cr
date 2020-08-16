module Grip
  class Application
    include Grip::DSL::Macros
    include Grip::DSL::Methods

    # Overload of `run` with the default startup logging.
    def run(port : Int32?, args = ARGV)
      run(port, args) { }
    end

    # Overload of `run` without port.
    def run(args = ARGV)
      run(nil, args: args)
    end

    # Overload of `run` to allow just a block.
    def run(args = ARGV, &block)
      run(nil, args: args, &block)
    end

    # The command to run a `Grip` application.
    #
    # If *port* is not given Grip will use `Grip::Config#port`
    #
    # To use custom command line arguments, set args to nil
    #
    def run(port : Int32? = nil, args = ARGV, &block)
      Grip::CLI.new args
      config = Grip.config
      config.setup
      config.port = port if port

      # Test environment doesn't need to have signal trap.
      if config.env != "test"
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

    def display_startup_message(config, server)
      addresses = server.addresses.map { |address| "#{config.scheme}://#{address}" }.join ", "
      puts "[#{Grip.config.env}] Grip is listening at #{addresses}"
    end

    def stop
      raise "Grip is already stopped." if !Grip.config.running
      if server = Grip.config.server
        server.close unless server.closed?
        Grip.config.running = false
      else
        raise "Grip.config.server is not set. Please use Grip.run to set the server."
      end
    end

    private def setup_trap_signal
      Signal::INT.trap do
        self.stop
        exit
      end
    end
  end
end
