module Grip
  module Routers
    class Http < Base
      CACHE_LIMIT = 1024
      property routes : Radix::Tree(Route)
      property cache : Hash(String, Radix::Result(Route))

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] received a request, path: #{context.request.path}, method: #{context.request.method}."
        {% end %}

        route = find_route(
          context.request.method.as(String),
          context.request.path
        )

        raise Exceptions::NotFound.new if !route.found?
        return context if context.response.closed?

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, route.params)

        payload = route.payload

        if payload.override
          payload.call_into_override(context)
        else
          payload.handler.call(context)
        end

        context
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Symbol? | Array(Symbol)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?) : Void
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] added an http route, path: #{path}, method: #{method}, handler: #{handler}, via: #{via}, override: #{override}."
        {% end %}
        add_to_radix_tree(method, path, Route.new(method, path, handler, via, override))
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        lookup_path = radix_path(verb, path)

        if cached_route = @cache[lookup_path]?
          return cached_route
        end

        route = @routes.find(lookup_path)

        if route.found?
          @cache.clear if @cache.size == CACHE_LIMIT
          @cache[lookup_path] = route
        end

        route
      end

      private def radix_path(method, path)
        '/' + method.downcase + path
      end

      private def add_to_radix_tree(method, path, route)
        node = radix_path method, path
        @routes.add node, route
      end
    end
  end
end
