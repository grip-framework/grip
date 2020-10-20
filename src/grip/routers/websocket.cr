module Grip
  module Routers
    class WebSocket < Base
      CACHE_LIMIT = 1024
      property routes : Radix::Tree(Route)
      property cache : Hash(String, Radix::Result(Route))

      alias Context = HTTP::Server::Context

      def initialize
        @routes = Radix::Tree(Route).new
        @cache = Hash(String, Radix::Result(Route)).new
      end

      def call(context : Context)
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] received a request, path: #{context.request.path}, method: #{context.request.method}."
        {% end %}

        route = find_route("", context.request.path)

        unless route.found? && websocket_upgrade_request?(context)
          return call_next(context)
        end

        context.parameters = Grip::Parsers::ParameterBox.new(context.request, route.params)
        payload = route.payload
        payload.match_via_keyword(context)
        payload.handler.call(context)

        if context.response.status_code.in?([400, 401, 403, 404, 405, 500])
          raise Exception.new("Routing layer has failed to process the request.")
        end

        context
      end

      def find_route(_verb : String, path : String) : Radix::Result(Route)
        lookup_path = "/ws" + path

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

      def add_route(method : String, path : String, handler : Grip::Controllers::Base, via : Array(Pipes::Base)?, override : Proc(Context, Context)?) : Void
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
