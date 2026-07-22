module Grip
  module Handlers
    class Pipeline < Base
      # Use instance cache instead of class constant for thread safety
      @pipe_cache : Hash(Array(Symbol), Array(::HTTP::Handler))

      property pipeline : Hash(Symbol, Array(::HTTP::Handler))
      property http_handler : ::HTTP::Handler?
      property server_sent_handler : ::HTTP::Handler?
      property websocket_handler : ::HTTP::Handler?

      def initialize(
        @http_handler = nil,
        @server_sent_handler = nil,
        @websocket_handler = nil
      )
        @pipeline = Hash(Symbol, Array(::HTTP::Handler)).new
        @pipe_cache = Hash(Array(Symbol), Array(::HTTP::Handler)).new
      end

      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      @[AlwaysInline]
      def call(context : ::HTTP::Server::Context)
        # Try WebSocket first if handler exists
        if websocket = @websocket_handler
          if match_via_websocket(context, websocket.as(WebSocket))
            return call_next(context)
          end
        end

        if server_sent = @server_sent_handler
          if match_via_server_sent(context, server_sent.as(ServerSent))
            return call_next(context)
          end
        end

        # Try HTTP if handler exists
        if http = @http_handler
          if match_via_http(context, http.as(HTTP))
            return call_next(context)
          end
        end

        call_next(context)
      end

      def add_pipe(
        valve : Symbol,
        pipe : ::HTTP::Handler,
        http_handler : ::HTTP::Handler? = nil,
        server_sent_handler : ::HTTP::Handler? = nil,
        websocket_handler : ::HTTP::Handler? = nil
      ) : Nil
        @http_handler = http_handler
        @server_sent_handler = server_sent_handler
        @websocket_handler = websocket_handler

        handlers = @pipeline[valve] ||= Array(::HTTP::Handler).new
        handlers << pipe
        handlers[-2]?.try &.next = pipe

        # Invalidate cache when pipes change
        @pipe_cache.clear
      end

      @[AlwaysInline]
      def get(valve : Symbol) : Array(::HTTP::Handler)?
        @pipeline[valve]?
      end

      def get(valves : Array(Symbol)) : Array(::HTTP::Handler)
        # Check cache first
        if cached = @pipe_cache[valves]?
          return cached
        end

        # Build pipe array
        pipes = Array(::HTTP::Handler).new(valves.size * 2) # Size hint

        valves.each do |valve|
          if valve_pipes = @pipeline[valve]?
            valve_pipes.each { |pipe| pipes << pipe }
          end
        end

        @pipe_cache[valves] = pipes
        pipes
      end

      @[AlwaysInline]
      def get(valve : Nil) : Nil
        nil
      end

      @[AlwaysInline]
      private def match_via_websocket(context : ::HTTP::Server::Context, websocket_handler : WebSocket) : Bool
        # Check upgrade first (cheaper than route lookup)
        return false unless websocket_handler.websocket_upgrade_request?(context)

        route = websocket_handler.find_route("", context.request.path)
        return false unless route.found?

        context.parameters = Parsers::ParameterBox.new(context.request, route.params)
        route.payload.process_pipeline(context, self)
        true
      end

      @[AlwaysInline]
      private def match_via_server_sent(context : ::HTTP::Server::Context, server_sent : ServerSent) : Bool
        route = server_sent.find_route(context.request.method, context.request.path)

        # Try ALL fallback if not found
        unless route.found?
          route = server_sent.find_route("ALL", context.request.path)
          return false unless route.found?
        end

        context.parameters = Parsers::ParameterBox.new(context.request, route.params)
        route.payload.process_pipeline(context, self)
        true
      end

      @[AlwaysInline]
      private def match_via_http(context : ::HTTP::Server::Context, http : HTTP) : Bool
        route = http.find_route(context.request.method, context.request.path)

        # Try ALL fallback if not found
        unless route.found?
          route = http.find_route("ALL", context.request.path)
          return false unless route.found?
        end

        context.parameters = Parsers::ParameterBox.new(context.request, route.params)
        route.payload.process_pipeline(context, self)
        true
      end
    end
  end
end
