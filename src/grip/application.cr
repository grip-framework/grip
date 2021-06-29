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
    private property pipeline_handler : Grip::Handlers::Pipeline
    private property websocket_handler : Grip::Routers::WebSocket
    private property forward_handler : Grip::Handlers::Forward

    private property scopes : Array(String) = [] of String
    private property valves : Array(Symbol) = [] of Symbol

    private property valve : Symbol?
    private property router : Array(HTTP::Handler)
    private property swagger_builder : Swagger::Builder

    def initialize
      @http_handler = Grip::Routers::Http.new
      @websocket_handler = Grip::Routers::WebSocket.new
      @pipeline_handler = Grip::Handlers::Pipeline.new(@http_handler, @websocket_handler)
      @exception_handler = Grip::Handlers::Exception.new
      @forward_handler = Grip::Handlers::Forward.new
      @swagger_builder = Swagger::Builder.new(
        title: title(),
        version: version(),
        description: description(),
        terms_url: terms_url(),
        contact: contact(),
        license: license(),
        authorizations: authorizations()
      )

      @router = router

      routes()
    end

    def title : String
      "API Documentation"
    end

    def version : String
      "1.0.0"
    end

    def description : String
      ""
    end

    def terms_url : String
      ""
    end

    def contact : Swagger::Contact?
      Swagger::Contact.new("icyleaf", "icyleaf.cn@gmail.com", "http://icyleaf.com")
    end

    def license : Swagger::License?
      Swagger::License.new("MIT", "https://github.com/icyleaf/swagger/blob/master/LICENSE")
    end

    def authorizations : Array(Swagger::Authorization)
      [] of Swagger::Authorization
    end

    def document : Swagger::Builder
      @swagger_builder
    end

    def root : Array(HTTP::Handler)
      [] of HTTP::Handler
    end

    def custom : Array(HTTP::Handler)
      [] of HTTP::Handler
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

    protected def router : Array(HTTP::Handler)
      [
        @exception_handler,
        @pipeline_handler,
        @forward_handler,
        @websocket_handler,
        @http_handler,
      ] of HTTP::Handler
    end

    def server : HTTP::Server
      custom.each do |handler|
        @router.insert(@router.size - 4, handler)
      end

      root.each do |handler|
        @router.insert(@router.size - 2, handler)
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
