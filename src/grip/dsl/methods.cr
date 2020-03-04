module Grip
  module DSL
    module Methods
      def pipeline(name, pipes)
        pipes.each do |pipe|
          Grip::Core::Pipeline::INSTANCE.add_pipe(name, pipe)
        end
      end

      def pipe_through(name, context : HTTP::Server::Context)
        Grip::Core::Pipeline::INSTANCE.pipeline[name].each do |pipe|
          pipe.call(context)
        end
      end

      def error(status_code : Int32, &block : HTTP::Server::Context, Exception -> _)
        Grip.config.add_error_handler status_code, &block
      end

      def headers(context, additional_headers)
        context.response.headers.merge!(additional_headers)
      end

      def headers(context, header, value)
        context.response.headers[header] = value
      end

      def json(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        content.to_json
      end

      def html(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/html"})
        content
      end

      def text(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/plain"})
        content
      end

      def stream(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "application/octetstream"})
        content
      end

      def json(context : HTTP::Server::Context)
        context.params.json
      end

      def query(context : HTTP::Server::Context)
        context.params.query
      end

      def url(context : HTTP::Server::Context)
        context.params.url
      end

      def ws_url(context : HTTP::Server::Context)
        context.ws_route_lookup.params
      end

      def headers(context : HTTP::Server::Context)
        context.request.headers
      end

      def add_handler(handler : HTTP::Handler)
        Grip.config.add_handler handler
      end

      def add_handler(handler : HTTP::Handler, position : Int32)
        Grip.config.add_handler handler, position
      end
    end
  end
end
