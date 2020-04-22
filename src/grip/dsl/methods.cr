module Grip
  module DSL
    module Methods
      #
      # DSL for pipeline and error declaration.
      #

      def pipeline(name, pipes)
        pipes.each do |pipe|
          Grip::Core::Pipeline::INSTANCE.add_pipe(name, pipe)
        end
      end

      def error(status_code : Int32, &block : HTTP::Server::Context, Exception -> _)
        Grip.config.add_error_handler status_code, &block
      end

      #
      # Request flow control
      #

      def json(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "application/json"})
        context.response.print(content.to_json)
        context
      end

      def html(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/html"})
        context.response.print(content)
        context
      end

      def text(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/plain"})
        context.response.print(content)
        context
      end

      def stream(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "application/octetstream"})
        context.response.print(content)
        context
      end

      def redirect(context, url : String, status_code = HTTP::Status::FOUND, *, body : String? = nil)
        context.response.headers.add "Location", url
        context.response.status_code = status_code.to_i
        context.response.print(body) if body
        context
      end

      #
      # Parsed parameter shortcuts
      #

      def json(context : HTTP::Server::Context)
        context.params.json
      end

      def query(context : HTTP::Server::Context)
        context.params.query
      end

      def url(context : HTTP::Server::Context)
        if context.params.url.size != 0
          context.params.url
        elsif context.ws_route_lookup.params.size != 0
          context.ws_route_lookup.params
        else
          context.params.url || context.ws_route_lookup.params
        end
      end

      def headers(context : HTTP::Server::Context)
        context.request.headers
      end

      #
      # Header parameter control
      #

      def headers(context, additional_headers)
        context.response.headers.merge!(additional_headers)
        context
      end

      def headers(context, header, value)
        context.response.headers[header] = value
        context
      end

      #
      # Middleware control
      #

      def add_handler(handler : HTTP::Handler)
        Grip.config.add_handler handler
      end

      def add_handler(handler : HTTP::Handler, position : Int32)
        Grip.config.add_handler handler, position
      end
    end
  end
end
