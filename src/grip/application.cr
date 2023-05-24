module Grip
  # `Grip::Application` is a building class which initializes the crucial parts of the
  # web-framework.
  class Application
    include Grip::Macros::Dsl

    getter environment : String = "development"
    getter serve_static : Bool = false

    getter http_handler : Grip::Routers::Http
    getter exception_handler : Grip::Handlers::Exception
    getter pipeline_handler : Grip::Handlers::Pipeline
    getter websocket_handler : Grip::Routers::WebSocket
    getter static_handler : Grip::Handlers::Static?

    property router : Array(HTTP::Handler)

    getter scopes : Array(String) = [] of String
    getter valves : Array(Symbol) = [] of Symbol

    getter valve : Symbol?

    def initialize(@environment : String = "development", @serve_static : Bool = false)
      @http_handler = Grip::Routers::Http.new
      @websocket_handler = Grip::Routers::WebSocket.new
      @pipeline_handler = Grip::Handlers::Pipeline.new(@http_handler, @websocket_handler)
      @exception_handler = Grip::Handlers::Exception.new(@environment)

      if serve_static
        @static_handler = Grip::Handlers::Static.new(pubilc_dir, fallthrough, directory_listing)
      end

      @router = [
        @exception_handler,
        @pipeline_handler,
        @websocket_handler,
        @http_handler,
      ] of HTTP::Handler
    end

    def host : String
      "0.0.0.0"
    end

    def port : Int32
      4004
    end

    def reuse_port : Bool
      false
    end

    def pubilc_dir : String
      "./public"
    end

    def fallthrough : Bool
      false
    end

    def directory_listing : Bool
      false
    end

    def server : HTTP::Server
      if serve_static
        @router.insert(1, @static_handler.not_nil!)
      end

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
        context = OpenSSL::SSL::Context::Server.new

        context
          .private_key = key_file

        context
          .certificate_chain = cert_file

        context
      end
    {% end %}

    protected def schema : String
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

      Log.info { "Listening at #{schema}://#{host}:#{port}" }

      if @environment != "test"
        Process.on_interrupt { exit }
        server.listen
      end
    end
  end
end
