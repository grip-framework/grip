module Grip
  module DSL
    # `Grip::DSL::Methods` provides a super-set of shortcuts which provide
    # an easy to use DSL to the routing/response handling.
    #
    # ```
    # class Example
    #   include Grip::DSL::Methods
    #   include HTTP::Handler
    #   
    #   def call(context)
    #     json!(
    #       context,
    #       "Hello, World!"
    #     )
    #   end
    # end
    # ```
    module Methods
      # `Grip::DSL::Methods#json!` responds with JSON content.
      def json!(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "application/json"})
        context.response.print(content.to_json)
        context
      end

      # `Grip::DSL::Methods#html!` responds with HTML content.
      def html!(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/html"})
        context.response.print(content)
        context
      end

      # `Grip::DSL::Methods#text!` responds with text content.
      def text!(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "text/plain"})
        context.response.print(content)
        context
      end

      # `Grip::DSL::Methods#stream!` responds with binary content.
      def stream!(context, content, status_code = HTTP::Status::OK)
        context.response.status_code = status_code.to_i
        context.response.headers.merge!({"Content-Type" => "application/octetstream"})
        context.response.print(content)
        context
      end

      # `Grip::DSL::Methods#json?` returns the parsed JSON content from an endpoint.
      def json?(context : HTTP::Server::Context)
        context.params.json
      end

      # `Grip::DSL::Methods#query?` returns the parsed `GET` query parameters from an endpoint.
      def query?(context : HTTP::Server::Context)
        context.params.query
      end

      # `Grip::DSL::Methods#body?` returns the parsed URL encoded parameters from an endpoint.
      def body?(context : HTTP::Server::Context)
        context.params.body
      end

      # `Grip::DSL::Methods#file?` returns the parsed multipart data from an endpoint.
      def file?(context : HTTP::Server::Context)
        context.params.file
      end

      # `Grip::DSL::Methods#url?` returns the parsed URL data from an endpoint.
      def url?(context : HTTP::Server::Context)
        if context.params.url.size != 0
          context.params.url
        elsif context.ws_route_lookup.params.size != 0
          context.ws_route_lookup.params
        else
          context.params.url || context.ws_route_lookup.params
        end
      end
    end
  end
end
