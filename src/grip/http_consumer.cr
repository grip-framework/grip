module Grip
  # `Grip::Handler` is a subclass of `HTTP::Handler`.
  #
  # It adds `route`, `route_match?`
  # These methods are useful for the conditional execution of custom handlers .
  class HttpConsumer < BaseConsumer
    # Helper methods for control flow manipulation, etc.
    def redirect(req, to)
      req.redirect to
    end

    def get(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def post(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def put(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def patch(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def delete(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def options(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def head(req : HTTP::Server::Context)
      req.response.status_code = 404
    end

    def call(req : HTTP::Server::Context)
      case req.request.method
      when "GET"
        get(req)
      when "POST"
        post(req)
      when "PUT"
        put(req)
      when "PATCH"
        patch(req)
      when "DELETE"
        delete(req)
      when "OPTIONS"
        options(req)
      when "HEAD"
        head(req)
      else
        call_next(req)
      end
    end

    macro json
      req.params.json
    end

    macro query
      req.params.query
    end

    macro url
      req.params.url
    end

    macro headers
      req.request.headers
    end
  end
end
