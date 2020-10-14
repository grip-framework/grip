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
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating an HTTP handler."
      {% end %}
      Grip::Routers::Http.new
    end

    def filter_handler(http : Grip::Routers::Http) : Grip::Handlers::Filter
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating a filter handler."
      {% end %}
      Grip::Handlers::Filter.new(http)
    end

    def exception_handler : Grip::Handlers::Exception
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating an exception handler."
      {% end %}
      Grip::Handlers::Exception.new
    end

    def pipeline_handler : Grip::Handlers::Pipeline
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating a pipeline storage."
      {% end %}
      Grip::Handlers::Pipeline.new
    end

    def websocket_handler : Grip::Routers::WebSocket
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating a websocket handler."
      {% end %}
      Grip::Routers::WebSocket.new
    end

    def log_handler : Grip::Handlers::Log
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] creating a log handler."
      {% end %}
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
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] building an array out of `HTTP::Handler` components."
      {% end %}

      {% if flag?(:minimal) %}
        [
          @exception,
          @http,
        ] of HTTP::Handler
      {% elsif flag?(:minimal_with_logs) %}
        [
          @log,
          @exception,
          @http,
        ] of HTTP::Handler
      {% elsif flag?(:logs) %}
        [
          @log,
          @exception,
          @filter_handler,
          @websocket,
          @http,
        ] of HTTP::Handler
      {% else %}
        [
          @exception,
          @filter_handler,
          @websocket,
          @http,
        ] of HTTP::Handler
      {% end %}
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

    {% unless flag?(:with_openssl) %}
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
        {% if flag?(:with_openssl) %}
          if ssl
            server.bind_tls(host, port, ssl, reuse_port)
          else
            server.bind_tcp(host, port, reuse_port)
          end
        {% else %}
          server.bind_tcp(host, port, reuse_port)
        {% end %}
      end

      {% if flag?(:verbose) && !flag?(:test) %}
        puts "#{Time.utc} [info] listening at #{schema}://#{host}:#{port}."
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
