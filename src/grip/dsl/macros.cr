module Grip
  module Dsl
    module Macros
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          @pipe_line.add_pipe({{name}}, pipe)
        end
      end

      {% if flag?(:minimal) || flag?(:minimal_with_logs) %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
            \{% if kwargs[:override] && kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:override] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                nil
              )
            \{% else %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                nil
              )
            \{% end %}
          end
        {% end %}

        macro error(error_code, resource)
          @exception.handlers[\{{error_code}}] = \{{resource}}.new
        end
      {% elsif flag?(:logs) %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
            \{% if kwargs[:override] && kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:override] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                nil
              )
            \{% else %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                nil
              )
            \{% end %}
          end
        {% end %}

        macro error(error_code, resource)
          @exception.handlers[\{{error_code}}] = \{{resource}}.new
        end

        macro ws(route, resource, **kwargs)
          \{% if kwargs[:via] %}
            @websocket.add_route(\{{ route }}, \{{ resource }}.new, @pipe_line.get(\{{kwargs[:via]}}), nil)
          \{% else %}
            @websocket.add_route(\{{ route }}, \{{ resource }}.new, nil, nil)
          \{% end %}
        end
  
        macro error(error_code, resource)
          @exception.handlers[\{{error_code}}] = \{{resource}}.new
        end
  
        macro filter(type, method, path, resource, **kwargs)
          \{% if kwargs[:via] %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, \{{path}}, \{{resource}}.new, @pipe_line.get(\{{kwargs[:via]}}))
          \{% else %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, \{{path}}, \{{resource}}.new, nil)
          \{% end %}
        end
      {% else %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
            \{% if kwargs[:override] && kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:override] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{ resource }}).\{{kwargs[:override].id}}(context)}
              )
            \{% elsif kwargs[:via] %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                @pipe_line.get(\{{kwargs[:via]}}),
                nil
              )
            \{% else %}
              @http.add_route(
                {{ http_method }}.to_s.upcase,
                \{{ route }},
                \{{ resource }}.new.as(Grip::Controllers::Base),
                nil,
                nil
              )
            \{% end %}
          end
        {% end %}

        macro error(error_code, resource)
          @exception.handlers[\{{error_code}}] = \{{resource}}.new
        end

        macro ws(route, resource, **kwargs)
          \{% if kwargs[:via] %}
            @websocket.add_route(\{{ route }}, \{{ resource }}.new, @pipe_line.get(\{{kwargs[:via]}}), nil)
          \{% else %}
            @websocket.add_route(\{{ route }}, \{{ resource }}.new, nil, nil)
          \{% end %}
        end
  
        macro filter(type, method, path, resource, **kwargs)
          \{% if kwargs[:via] %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, \{{path}}, \{{resource}}.new, @pipe_line.get(\{{kwargs[:via]}}))
          \{% else %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, \{{path}}, \{{resource}}.new, nil)
          \{% end %}
        end
      {% end %}
    end
  end
end
