module Grip
  module Handlers
    # :nodoc:
    class Pipeline
      include HTTP::Handler

      property pipeline : Hash(Symbol, Array(Pipes::Base))

      CACHED_PIPES = {} of Array(Symbol) => Array(Pipes::Base)

      {% if flag?(:websocket) %}
        def initialize(@http_handler : Grip::Routers::Http, @websocket_handler : Grip::Routers::WebSocket)
          @pipeline = Hash(Symbol, Array(Pipes::Base)).new
        end
      {% else %}
        def initialize(@http_handler : Grip::Routers::Http)
          @pipeline = Hash(Symbol, Array(Pipes::Base)).new
        end
      {% end %}

      def add_pipe(valve : Symbol, pipe : Pipes::Base)
        if @pipeline.has_key?(valve)
          @pipeline[valve].push(pipe)
        else
          @pipeline[valve] = [pipe.as(Pipes::Base)]
        end
      end

      def get(valve : Symbol)
        @pipeline[valve]
      end

      def get(valves : Array(Symbol))
        if CACHED_PIPES[valves]?
          return CACHED_PIPES[valves]
        end

        pipes = [] of Pipes::Base

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

      {% if flag?(:websocket) %}
        def match_via_websocket(context : HTTP::Server::Context) : Bool
          route = @websocket_handler.find_route("", context.request.path)

          unless route.found? && @websocket_handler.websocket_upgrade_request?(context)
            return false
          end

          route.payload.match_via_keyword(context, self)

          true
        end
      {% end %}

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
        {% if flag?(:websocket) %}
          return call_next(context) if match_via_websocket(context)
        {% end %}

        return call_next(context) if match_via_http(context)

        call_next(context)
      end
    end
  end
end
