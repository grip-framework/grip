module Grip::Helpers::Macros
  HTTP_METHODS = %i(get post put patch delete options head)

  macro json(context, content, status_code = HTTP::Status::OK)
    {{context}}.response.status_code = {{status_code}}.to_i
    {{content}}.to_json
  end

  macro html(context, content, status_code = HTTP::Status::OK)
    {{context}}.response.status_code = {{status_code}}.to_i
    {{context}}.response.headers.merge!({"Content-Type" => "text/html"})
    {{content}}
  end

  macro text(context, content, status_code = HTTP::Status::OK)
    {{context}}.response.status_code = {{status_code}}.to_i
    {{context}}.response.headers.merge!({"Content-Type" => "text/plain"})
    {{content}}
  end

  macro stream(context, content, status_code = HTTP::Status::OK)
    {{context}}.response.status_code = {{status_code}}.to_i
    {{context}}.response.headers.merge!({"Content-Type" => "application/octetstream"})
    {{content}}
  end

  {% for http_method in HTTP_METHODS %}
    macro {{http_method.id}}(route, resource)
      Grip::HttpRouteHandler::INSTANCE.add_route({{ http_method }}.to_s.upcase, \{{ route }}, \{{ resource }}.new, nil)
    end

    macro {{http_method.id}}(route, resource, override)
      Grip::HttpRouteHandler::INSTANCE.add_route({{ http_method }}.to_s.upcase, \{{ route }}, \{{ resource }}.new, -> (req : HTTP::Server::Context) { \{{ resource }}.new.as(\{{ resource }}).\{{override.id}}(req) })
    end
  {% end %}

  macro resource(route, resource)
    {% for http_method in HTTP_METHODS %}
      Grip::HttpRouteHandler::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil)
    {% end %}
  end

  macro resource(route, resource, **kwargs)
    {% if kwargs[:only] %}
      {% for http_method in kwargs[:only] %}
        Grip::HttpRouteHandler::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil)
      {% end %}
    {% elsif kwargs[:exclude] %}
      {% for http_method in HTTP_METHODS %}
        if !{{kwargs[:exclude]}}.any?({{http_method}})
          Grip::HttpRouteHandler::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil)
        end
      {% end %}
    {% end %}
  end

  macro ws(route, resource)
    Grip::WebSocketRouteHandler::INSTANCE.add_route({{ route }}, {{ resource }}.new)
  end

  macro headers(context, additional_headers)
    {{context}}.response.headers.merge!({{additional_headers}})
  end

  macro headers(context, header, value)
    {{context}}.response.headers[{{header}}] = {{value}}
  end
end
