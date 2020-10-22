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

    private property http_handler : Grip::Routers::Http
    private property exception_handler : Grip::Handlers::Exception
    private property pipeline_handler : Grip::Handlers::Pipeline?

    private property log_handler : HTTP::Handler?
    private property swagger_handler : Grip::Handlers::Swagger?
    private property static_handler : Grip::Handlers::Static?
    private property websocket_handler : Grip::Routers::WebSocket?

    private property scope_path : String = ""
    private property pipethrough_valve : Array(Symbol)? | Symbol? = nil
    private property router : Array(HTTP::Handler)

    def initialize
      @http_handler = Grip::Routers::Http.new
      @exception_handler = Grip::Handlers::Exception.new

      {% if flag?(:websocket) %}
        @websocket_handler = Grip::Routers::WebSocket.new

        @pipeline_handler = Grip::Handlers::Pipeline.new(@http_handler, @websocket_handler.not_nil!)
      {% else %}
        @pipeline_handler = Grip::Handlers::Pipeline.new(@http_handler)
      {% end %}

      {% if flag?(:swagger) %}
        @swagger_handler = Grip::Handlers::Swagger.new(path, title, version, description, authorizations)
      {% end %}

      {% if flag?(:serveStatic) %}
        @static_handler = Grip::Handlers::Static.new(public_dir, fallthrough, directory_listing)
      {% end %}

      {% if flag?(:logs) %}
        @log_handler = Grip::Handlers::Log.new
      {% end %}

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

    {% if flag?(:serveStatic) %}
      def public_dir : String
        "./public"
      end

      def fallthrough : Bool
        false
      end

      def directory_listing : Bool
        false
      end
    {% end %}

    def router : Array(HTTP::Handler)
      {% if flag?(:verbose) %}
        puts "#{Time.utc} [info] building an array out of `HTTP::Handler` components."
      {% end %}

      [
        @exception_handler,
        @pipeline_handler.not_nil!,
        @http_handler,
      ] of HTTP::Handler
    end

    def server : HTTP::Server
      {% if flag?(:swagger) %}
        @router.insert(@router.size - 1, @swagger_handler.not_nil!)
      {% end %}

      {% if flag?(:serveStatic) %}
        @router.insert(2, @static_handler.not_nil!)
      {% end %}

      {% if flag?(:logs) %}
        @router.insert(0, @log_handler.not_nil!)
      {% end %}

      {% if flag?(:websocket) %}
        @router.insert(@router.size - 1, @websocket_handler.not_nil!)
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

      puts "#{Time.utc} [info] listening at #{schema}://#{host}:#{port}."

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
