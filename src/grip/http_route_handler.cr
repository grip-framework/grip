require "radix"
require "json"

module Grip
  class HttpRouteHandler
    include HTTP::Handler

    INSTANCE            = new
    CACHED_ROUTES_LIMIT = 1024
    property routes, cached_routes

    def initialize
      @routes = Radix::Tree(HttpRoute).new
      @cached_routes = Hash(String, Radix::Result(HttpRoute)).new
    end

    def call(context : HTTP::Server::Context)
      process_request(context)
    end

    # Adds a given route to routing tree. As an exception each `GET` route additionaly defines
    # a corresponding `HEAD` route.
    def add_route(method : String, path : String, handler : Grip::HttpConsumer)
      add_to_radix_tree(method, path, HttpRoute.new(method, path, handler))
    end

    # Looks up the route from the Radix::Tree for the first time and caches to improve performance.
    def lookup_route(verb : String, path : String)
      lookup_path = radix_path(verb, path)

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

    # Processes the route if it's a match. Otherwise renders 404.
    private def process_request(context)
      raise Grip::Exceptions::RouteNotFound.new(context) unless context.route_found?
      return if context.response.closed?
      content = context.route.handler.call(context)
      if !Grip.config.error_handlers.empty? && Grip.config.error_handlers.has_key?(context.response.status_code)
        raise Grip::Exceptions::CustomException.new(context)
      end
      # Hacky solution around the 'Error: can't cast (Bool | HTTP::Server::Context | UInt64 | Nil) to Tuple(T)' when no routes are defined.
      if !content.is_a?(Bool | HTTP::Server::Context | UInt64 | Nil)
        content = content.as(Tuple)
        # Implemented from https://restfulapi.net/http-status-codes/
        case content[0]
        when :OK, :ok, 200
          context.response.status_code = 200
        when :CREATED, :created, 201
          context.response.status_code = 201
        when :ACCEPTED, :accepted, 202
          context.response.status_code = 202
        when :NO_CONTENT, :no_content, 204
          context.response.status_code = 204
        when :MOVED_PERMANENTLY, :moved_permanently, 301
          context.response.status_code = 301
        when :FOUND, :found, 302
          context.response.status_code = 302
        when :SEE_OTHER, :see_other, 303
          context.response.status_code = 303
        when :NOT_MODIFIED, :not_modified, 304
          context.response.status_code = 304
        when :TEMPORARY_REDIRECT, :temporary_redirect, 307
          context.response.status_code = 307
        when :BAD_REQUEST, :bad_request, 400
          context.response.status_code = 400
        when :UNAUTHORIZED, :unauthorized, 401
          context.response.status_code = 401
        when :FORBIDDEN, :forbidden, 403
          context.response.status_code = 403
        when :NOT_FOUND, :not_found, 404
          context.response.status_code = 404
        when :METHOD_NOT_ALLOWED, :method_not_allowed, 405
          context.response.status_code = 405
        when :NOT_ACCEPTABLE, :not_acceptable, 406
          context.response.status_code = 406
        when :PRECONDITION_FAILED, :precondition_failed, 412
          context.response.status_code = 412
        when :INTERNAL_SERVER_ERROR, :internal_server_error, 500
          context.response.status_code = 500
        when :NOT_IMPLEMENTED, :not_implemented, 501
          context.response.status_code = 501
          # Feeling cute, might delete later.
        when :IM_A_TEAPOT, :im_a_teapot, 418
          context.response.status_code = 418
        else
          context.response.status_code = content.[0].to_i
        end
        if context.response.headers["Content-Type"] == "application/json"
          if !content[1].is_a?(String)
            context.response.print(content[1].to_json)
          else
            context.response.print(content[1])
          end
        else
          context.response.print(content[1])
        end
      else
        context.response.print(context)
      end
      context
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
