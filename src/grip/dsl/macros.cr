module Grip
  module DSL
    module Macros
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          Grip::Core::Pipeline::INSTANCE.add_pipe({{name}}, pipe)
        end
      end

      {% for http_method in HTTP_METHODS %}
        macro {{http_method.id}}(route, resource, **kwargs)
          \{% if kwargs[:override] && kwargs[:via] %}
            Grip::Router::Http::INSTANCE.add_route(
              {{ http_method }}.to_s.upcase,
              \{{ route }},
              \{{ resource }}.new.as(Grip::Controllers::Base),
              \{{kwargs[:via]}},
              -> (context : HTTP::Server::Context) {
                \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
            )
          \{% elsif kwargs[:override] %}
            Grip::Router::Http::INSTANCE.add_route(
              {{ http_method }}.to_s.upcase,
              \{{ route }},
              \{{ resource }}.new.as(Grip::Controllers::Base),
              nil,
              -> (context : HTTP::Server::Context) {
                \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
            )
          \{% elsif kwargs[:via] %}
            Grip::Router::Http::INSTANCE.add_route(
              {{ http_method }}.to_s.upcase,
              \{{ route }},
              \{{ resource }}.new.as(Grip::Controllers::Base),
              \{{kwargs[:via]}},
              nil
            )
          \{% else %}
            Grip::Router::Http::INSTANCE.add_route(
              {{ http_method }}.to_s.upcase,
              \{{ route }},
              \{{ resource }}.new.as(Grip::Controllers::Base),
              nil,
              nil
            )
          \{% end %}
        end
      {% end %}

      macro resource(route, resource, **kwargs)
        {% for http_method in HTTP_METHODS %}
          {% if kwargs[:via] %}
            Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, {{kwargs[:via]}}, nil)
          {% else %}
            Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil, nil)
          {% end %}
        {% end %}
      end

      macro resource(route, resource, **kwargs)
        {% if kwargs[:only] && kwargs[:via] %}
          {% for http_method in kwargs[:only] %}
            Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, {{kwargs[:via]}}, nil)
          {% end %}
        {% elsif kwargs[:exclude] && kwargs[:via] %}
          {% for http_method in HTTP_METHODS %}
            if !{{kwargs[:exclude]}}.any?({{http_method}})
              Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, {{kwargs[:via]}}, nil)
            end
          {% end %}
        {% elsif kwargs[:only] %}
          {% for http_method in kwargs[:only] %}
            Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil, nil)
          {% end %}
        {% elsif kwargs[:exclude] %}
          {% for http_method in HTTP_METHODS %}
            if !{{kwargs[:exclude]}}.any?({{http_method}})
              Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, nil, nil)
            end
          {% end %}
        {% elsif kwargs[:via] %}
          {% for http_method in HTTP_METHODS %}
            if {{ kwargs[:via] }}
              Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, {{ kwargs[:via] }}, nil)
            end
          {% end %}
        {% else %}
          {% for http_method in HTTP_METHODS %}
            Grip::Router::Http::INSTANCE.add_route({{ http_method }}.to_s.upcase, {{ route }}, {{ resource }}.new, {{ kwargs[:via] }}, nil)
          {% end %} 
        {% end %}
      end

      macro ws(route, resource, **kwargs)
        {% if kwargs[:via] %}
          Grip::Router::WebSocket::INSTANCE.add_route({{ route }}, {{ resource }}.new, {{ kwargs[:via] }}, nil)
        {% else %}
          Grip::Router::WebSocket::INSTANCE.add_route({{ route }}, {{ resource }}.new, nil, nil)
        {% end %}
      end

      macro error(error_code, resource)
        Grip.config.add_error_handler({{error_code}}, {{resource}}.new)
      end

      macro filter(type, method, path, resource, **kwargs)
        {% if kwargs[:via] %}
          Grip::Core::Filter::INSTANCE.{{type.id}}({{method}}.to_s.upcase, {{path}}, {{resource}}.new, {{kwargs[:via]}})
        {% else %}
          Grip::Core::Filter::INSTANCE.{{type.id}}({{method}}.to_s.upcase, {{path}}, {{resource}}.new, nil)
        {% end %}
      end
    end
  end
end
