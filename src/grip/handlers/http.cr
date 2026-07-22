module Grip
  module Handlers
    class HTTP < Base
      CACHE_SIZE = 4096
      CACHE_MASK = CACHE_SIZE - 1

      VERB_IDS = {
        "GET" => 0_u8, "POST" => 1_u8, "PUT" => 2_u8, "DELETE" => 3_u8,
        "PATCH" => 4_u8, "HEAD" => 5_u8, "OPTIONS" => 6_u8, "ALL" => 255_u8,
      }

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
        route = Route.new(verb, path, handler, via, override)

        @has_all_routes = true if verb == "ALL"
        @routes.add(radix_path(verb, path), route)
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        hash = route_hash(verb, path)

        # Check cache
        if cached = cache_lookup(hash)
          return cached
        end

        # Radix lookup
        result = @routes.find(radix_path(verb, path))
        cache_store(hash, result) if result.found?
        result
      end

      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        return context if context.response.closed?

        route = resolve_route(context.request.method, context.request.path)
        raise Exceptions::NotFound.new unless route.found?

        context.parameters ||= Grip::Parsers::ParameterBox.new(context.request, route.params)
        execute_route(route.payload, context)
        context
      end

      private def resolve_route(verb : String, path : String) : Radix::Result(Route)
        hash = route_hash(verb, path)

        # Check cache first
        if cached = cache_lookup(hash)
          return cached
        end

        # Try exact verb
        result = @routes.find(radix_path(verb, path))

        if result.found?
          cache_store(hash, result)
          return result
        end

        # HEAD -> GET fallback
        if verb == "HEAD"
          get_result = @routes.find(radix_path("GET", path))

          if get_result.found?
            cache_store(hash, get_result)
            return get_result
          end
        end

        # ALL fallback
        if @has_all_routes
          all_result = @routes.find(radix_path("ALL", path))

          if all_result.found?
            cache_store(hash, all_result)
            return all_result
          end
        end

        # Return the not-found result
        result
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
      private def route_hash(verb : String, path : String) : UInt64
        verb_id = VERB_IDS[verb]? || 128_u8
        hash = verb_id.to_u64 << 56
        fnv_prime = 0x100000001b3_u64
        hash ^= 0xcbf29ce484222325_u64

        path.each_byte do |byte|
          hash ^= byte.to_u64
          hash &*= fnv_prime
        end

        hash
      end

      @[AlwaysInline]
      private def radix_path(verb : String, path : String) : String
        String.build(verb.bytesize + path.bytesize + 1) do |io|
          io << '/'
          io << verb
          io << path
        end
      end

      @[AlwaysInline]
      private def execute_route(route : Route, context : ::HTTP::Server::Context) : Nil
        if route.override
          route.execute_override(context)
        else
          route.handler.call(context)
        end
      end
    end
  end
end
