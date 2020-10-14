module Grip
  # `Grip::Application` is a building class which initializes the crucial parts of the
  # web-framework.
  #
  # ```
  # class Application < Grip::Application
  #   def routes
  #     pipeline :api, [
  #       Pipes::PoweredByHeader.new,
  #     ]
  #   end
  # end
  #
  # app = Application.new
  # app.run
  # ```
  abstract class Application
    include Grip::Dsl::Macros

    abstract def routes

    protected property http : Grip::Routers::Http
    protected property websocket : Grip::Routers::WebSocket
    protected property log : Grip::Handlers::Log
    protected property exception : Grip::Handlers::Exception
    protected property pipe_line : Grip::Handlers::Pipeline
    protected property filter_handler : Grip::Handlers::Filter

    protected property router : Array(HTTP::Handler)

    def initialize
      @http = http_handler
      @websocket = websocket_handler
      @log = log_handler
      @exception = exception_handler
      @pipe_line = pipeline_handler
      @filter_handler = filter_handler(http)

      @router = router
      routes()
    end

    def http_handler : Grip::Routers::Http
      Grip::Routers::Http.new
    end

    def filter_handler(http : Grip::Routers::Http) : Grip::Handlers::Filter
      Grip::Handlers::Filter.new(http)
    end

    def exception_handler : Grip::Handlers::Exception
      Grip::Handlers::Exception.new
    end

    def pipeline_handler : Grip::Handlers::Pipeline
      Grip::Handlers::Pipeline.new
    end

    def websocket_handler : Grip::Routers::WebSocket
      Grip::Routers::WebSocket.new
    end

    def log_handler : Grip::Handlers::Log
      Grip::Handlers::Log.new
    end

    def host : String
      "0.0.0.0"
    end

    def port : Int32
      5000
    end

    def reuse_port : Bool
      false
    end

    def router : Array(HTTP::Handler)
      [
        @log,
        @exception,
        @filter_handler,
        @websocket,
        @http,
      ] of HTTP::Handler
    end

    def server : HTTP::Server
      HTTP::Server.new(@router)
    end

    def key_file : String
      ENV["KEY"]? || ""
    end

    def cert_file : String
      ENV["CERTIFICATE"]? || ""
    end

    {% if flag?(:without_openssl) %}
      def ssl : Bool
        false
      end
    {% else %}
      def ssl : OpenSSL::SSL::Context::Server
        context =
          Grip::Ssl
            .new
            .context

        context
          .private_key = key_file

        context
          .certificate_chain = cert_file

        context
      end
    {% end %}

    private def schema : String
      ssl ? "https" : "http"
    end

    def run
      {% if !flag?(:test) %}
        setup_trap_signal()
      {% end %}

      server = self.server

      unless server.each_address { |_| break true }
        {% if flag?(:without_openssl) %}
          server.bind_tcp(host, port, reuse_port)
        {% else %}
          if ssl
            server.bind_tls(host, port, ssl, reuse_port)
          else
            server.bind_tcp(host, port, reuse_port)
          end
        {% end %}
      end

      {% if flag?(:verbose) && !flag?(:test) %}
        puts "Listening at #{schema}://#{host}:#{port}..."
      {% end %}

      {% if !flag?(:test) %}
        server.listen
      {% end %}
    end

    private def setup_trap_signal
      Signal::INT.trap do
        exit
      end
    end
  end
end
