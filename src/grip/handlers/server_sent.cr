module Grip
  module Handlers
    class ServerSent < Base
      CACHE_SIZE = 4096
      CACHE_MASK = CACHE_SIZE - 1

      getter routes : Radix::Tree(Route)

      @cache : Array(Tuple(UInt64, Radix::Result(Route)?))
      @has_all_routes : Bool = false

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Array(Tuple(UInt64, Radix::Result(Route)?)).new(CACHE_SIZE) { {0_u64, nil} }
      end

      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
        route = Route.new("", path, handler, via, override)
        @routes.add(radix_path(path), route)
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        hash = route_hash(path)

        if cached = cache_lookup(hash)
          return cached
        end

        result = @routes.find(radix_path(path))
        cache_store(hash, result) if result.found?
        result
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        return context if context.response.closed?

        route = find_route("", context.request.path)

        call_next(context) unless route.found?

        context.parameters ||= ::Grip::Parsers::ParameterBox.new(context.request, route.params)
        execute_route(route.payload, context)

        context
      end

      @[AlwaysInline]
      private def cache_lookup(hash : UInt64) : Radix::Result(Route)?
        slot = hash & CACHE_MASK

        4.times do |i|
          idx = (slot + i) & CACHE_MASK
          entry = @cache.unsafe_fetch(idx)
          return entry[1] if entry[0] == hash && entry[1]
          break if entry[0] == 0_u64 && i > 0
        end

        nil
      end

      @[AlwaysInline]
      private def cache_store(hash : UInt64, result : Radix::Result(Route)) : Nil
        slot = hash & CACHE_MASK

        4.times do |i|
          idx = (slot + i) & CACHE_MASK
          entry = @cache.unsafe_fetch(idx)

          if entry[0] == 0_u64 || entry[0] == hash
            @cache[idx] = {hash, result}
            return
          end
        end

        @cache[slot] = {hash, result}
      end

      @[AlwaysInline]
      private def route_hash(path : String) : UInt64
        hash = 0xcbf29ce484222325_u64
        fnv_prime = 0x100000001b3_u64

        path.each_byte do |byte|
          hash ^= byte.to_u64
          hash &*= fnv_prime
        end

        hash
      end

      @[AlwaysInline]
      private def radix_path(path : String) : String
        String.build(4 + path.bytesize) do |io|
          io << "/"
          io << "SSE"
          io << path
        end
      end

      @[AlwaysInline]
      private def execute_route(route : Route, context : ::HTTP::Server::Context) : Nil
        unless route.override
          raise ::Grip::Exceptions::InternalServerError.new("Route override is not defined for the server-sent event route")
        end

        route.execute_override(context)
      end
    end
  end
end
