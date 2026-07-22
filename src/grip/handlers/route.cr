module Grip
  module Handlers
    struct Route
      # Pre-computed empty array to avoid allocations
      EMPTY_VIA = [] of Symbol

      getter method : String
      getter path : String
      getter handler : ::HTTP::Handler
      getter via : Array(Symbol)
      getter override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)?

      # Pre-computed flags for fast path decisions
      getter? has_override : Bool
      getter? has_pipeline : Bool
      getter? is_static : Bool

      def initialize(
        @method : String,
        @path : String,
        @handler : ::HTTP::Handler,
        via : Symbol | Array(Symbol) | Nil = nil,
        @override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      )
        @via = normalize_via(via)
        @has_override = !@override.nil?
        @has_pipeline = !@via.empty?
        @is_static = !@path.includes?(':') && !@path.includes?('*')
      end

      @[AlwaysInline]
      def process_pipeline(
        context : ::HTTP::Server::Context,
        pipeline_handler : Grip::Handlers::Pipeline
      ) : ::HTTP::Server::Context
        # Skip pipeline lookup entirely if no via
        return context unless has_pipeline?
        execute_pipeline(context, pipeline_handler)
        context
      end

      @[AlwaysInline]
      def execute_override(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        # Direct call without .try since we check has_override? first
        @override.try(&.call(context))
        context
      end

      @[AlwaysInline]
      private def normalize_via(via : Symbol | Array(Symbol) | Nil) : Array(Symbol)
        case via
        when Symbol
          [via]
        when Array(Symbol)
          via
        else
          EMPTY_VIA
        end
      end

      @[AlwaysInline]
      private def execute_pipeline(
        context : ::HTTP::Server::Context,
        pipeline_handler : Grip::Handlers::Pipeline
      ) : Nil
        # Avoid iterator allocation with manual loop
        pipes = pipeline_handler.get(@via)

        i = 0

        while i < pipes.size
          pipes.unsafe_fetch(i).call(context)
          i += 1
        end
      end
    end
  end
end
