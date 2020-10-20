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

    private property http_handler : Grip::Routers::Base
    private property websocket_handler : Grip::Routers::Base
    private property log_handler : HTTP::Handler
    private property exception_handler : Grip::Handlers::Exception
    private property pipeline_handler : Grip::Handlers::Pipeline
    private property filter_handler : Grip::Handlers::Filter
    private property swagger_handler : Grip::Handlers::Swagger?

    private property scope_path : String = ""
    private property pipethrough_valve : Array(Symbol)? | Symbol? = nil
    private property router : Array(HTTP::Handler)

    def initialize
      @http_handler = Grip::Routers::Http.new
      @websocket_handler = Grip::Routers::WebSocket.new
      @log_handler = Grip::Handlers::Log.new
      @exception_handler = Grip::Handlers::Exception.new
      @pipeline_handler = Grip::Handlers::Pipeline.new
      {% if flag?(:swagger) %}
        @swagger_handler = Grip::Handlers::Swagger.new(path, title, version, description, authorizations)
      {% end %}
      @filter_handler = Grip::Handlers::Filter.new(@http_handler)
      @router = router

      routes()
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

    {% if flag?(:swagger) %}
      def path : String
        "/docs"
      end

      def title : String
        "API Documentation"
      end

      def version : String
        {{ `shards version`.chomp.stringify }}
      end

      def description : String
        "A documentation medium for the API"
      end

      def authorizations : Array(Swagger::Authorization)
        [
          Swagger::Authorization.jwt(description: "Use JWT Auth")
        ] of Swagger::Authorization
      end
    {% end %}

    def router : Array(HTTP::Handler)
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] building an array out of `HTTP::Handler` components."
      {% end %}

      {% if flag?(:minimal) %}
        [
          @exception_handler,
          @http_handler,
        ] of HTTP::Handler
      {% elsif flag?(:minimal_with_logs) %}
        [
          @log_handler,
          @exception_handler,
          @http_handler,
        ] of HTTP::Handler
      {% elsif flag?(:logs) %}
        [
          @log_handler,
          @exception_handler,
          @filter_handler,
          @websocket_handler,
          @http_handler,
        ] of HTTP::Handler
      {% else %}
        [
          @exception_handler,
          @filter_handler,
          @websocket_handler,
          @http_handler,
        ] of HTTP::Handler
      {% end %}
    end

    def server : HTTP::Server
      {% if flag?(:swagger) %}
        @router.insert(@router.size - 1, @swagger_handler.not_nil!)
      {% end %}

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
        setup_trap_signal()
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
