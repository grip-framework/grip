module Grip
  # `Grip::Application` is a building class which initializes the crucial parts of the
  # web-framework.
  class Application
    include Grip::Macros::Dsl

    getter environment : String = "development"

    getter http_handler : Grip::Routers::Http
    getter exception_handler : Grip::Handlers::Exception
    getter pipeline_handler : Grip::Handlers::Pipeline
    getter websocket_handler : Grip::Routers::WebSocket
    getter static_handlers : Array(Grip::Handlers::Static) = [] of Grip::Handlers::Static

    getter scopes : Array(String) = [] of String
    getter valves : Array(Symbol) = [] of Symbol
    getter valve : Symbol?
    
    property router : Array(HTTP::Handler)

    def initialize(@environment : String = "development")
      @http_handler = Grip::Routers::Http.new
      @websocket_handler = Grip::Routers::WebSocket.new
      @pipeline_handler = Grip::Handlers::Pipeline.new(@http_handler, @websocket_handler)
      @exception_handler = Grip::Handlers::Exception.new(@environment)

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

    def server : HTTP::Server
      @static_handlers.each do |handler|
        @router.insert(1, handler)
      end

      HTTP::Server.new(@router)
    end

    def key_file : String
      ENV["KEY"]? || ""
    end

    def cert_file : String
      ENV["CERTIFICATE"]? || ""
    end

    {% unless flag?(:ssl) %}
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
        {% if flag?(:ssl) %}
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
        {% begin %}
          {% version = Crystal::VERSION.gsub(/[^0-9.]/, "").split(".").map(&.to_i) %}

          {% major = version[0] %}
          {% minor = version[1] %}
          {% patch = version[2] %}

          # 0.X.X
          {% if major < 1 %}
            Signal::INT.trap { exit }
          {% end %}

          # 1.0.0 to 1.11.X
          {% if major == 1 && minor < 12 %}
            Process.on_interrupt { exit }
          {% end %}

          # 1.12.X to 1.X.X
          {% if major == 1 && minor >= 12 %}
            Process.on_terminate { exit }
          {% end %}
        {% end %}

        server.listen
      end
    end
  end
end
