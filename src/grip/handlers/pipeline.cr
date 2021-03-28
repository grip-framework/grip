module Grip
  module Handlers
    # :nodoc:
    class Pipeline
      include HTTP::Handler

      property pipeline : Hash(Symbol, Array(HTTP::Handler))

      CACHED_PIPES = {} of Array(Symbol) => Array(HTTP::Handler)

      def initialize(@http_handler : Grip::Routers::Http, @websocket_handler : Grip::Routers::WebSocket)
        @pipeline = Hash(Symbol, Array(HTTP::Handler)).new
      end

      def add_pipe(valve : Symbol, pipe : HTTP::Handler)
        if @pipeline.has_key?(valve)
          size = @pipeline[valve].size
          @pipeline[valve].push(pipe)
          @pipeline[valve].[size - 1].next = pipe
        else
          @pipeline[valve] = [pipe.as(HTTP::Handler)]
        end
      end

      def get(valve : Symbol)
        @pipeline[valve]
      end

      def get(valves : Array(Symbol))
        if CACHED_PIPES[valves]?
          return CACHED_PIPES[valves]
        end

        pipes = [] of HTTP::Handler

        valves.each do |valve|
          @pipeline[valve].each do |_pipe|
            pipes.push(_pipe)
          end
        end

        CACHED_PIPES[valves] = pipes
        pipes
      end

      def get(valve : Nil) : Nil
        nil
      end

      def match_via_websocket(context : HTTP::Server::Context) : Bool
        route = @websocket_handler.find_route("", context.request.path)

        unless route.found? && @websocket_handler.websocket_upgrade_request?(context)
          return false
        end

        route.payload.match_via_keyword(context, self)

        true
      end

      def match_via_http(context : HTTP::Server::Context) : Bool
        route = @http_handler.find_route(
          context.request.method.as(String),
          context.request.path
        )

        unless route.found?
          return false
        end

        route.payload.match_via_keyword(context, self)

        true
      end

      def call(context : HTTP::Server::Context)
        return call_next(context) if match_via_websocket(context)
        return call_next(context) if match_via_http(context)

        call_next(context)
      end
    end
  end
end
