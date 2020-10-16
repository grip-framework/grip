module Grip
  module Routers
    class WebSocket < Base
      CACHED_ROUTES_LIMIT = 1024
      property routes, cached_routes

      def initialize
        @routes = Radix::Tree(Route).new
        @cached_routes = Hash(String, Radix::Result(Route)).new
      end

      def call(context : HTTP::Server::Context)
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] received a request, path: #{context.request.path}, method: #{context.request.method}."
        {% end %}

        route = lookup_route("", context.request.path)

        unless route.found? && websocket_upgrade_request?(context)
          {% if flag?(:verbose) %}
            puts "#{Time.utc} [info] calling the next handler, didn't match a thing in websockets, path: #{context.request.path}, method: #{context.request.method}."
          {% end %}

          return call_next(context)
        end

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, route.params)
        payload = route.payload
        payload.match_via_keyword(context, payload.via)
        payload.handler.call(context)
      end

      def lookup_route(_verb : String, path : String)
        lookup_path = "/ws" + path

        if cached_route = @cached_routes[lookup_path]?
          return cached_route
        end

        route = @routes.find(lookup_path)

        if route.found?
          @cached_routes.clear if @cached_routes.size == CACHED_ROUTES_LIMIT
          @cached_routes[lookup_path] = route
        end

        route
      end

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Array(Pipes::Base)?, override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
        add_to_radix_tree path, Route.new("", path, handler, via, nil)
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] added a ws route, path: #{path}, handler: #{handler}, via: #{via}."
        {% end %}
      end

      private def add_to_radix_tree(path, websocket)
        node = radix_path "ws", path
        @routes.add node, websocket
      end

      private def radix_path(method, path)
        '/' + method.downcase + path
      end

      private def websocket_upgrade_request?(context)
        return unless upgrade = context.request.headers["Upgrade"]?
        return unless upgrade.compare("websocket", case_insensitive: true) == 0

        context.request.headers.includes_word?("Connection", "Upgrade")
      end
    end
  end
end
