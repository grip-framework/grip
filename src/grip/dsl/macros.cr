module Grip
  module Dsl
    module Macros
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          @pipeline_handler.add_pipe({{name}}, pipe)
        end
      end

      macro pipe_through(valve)
        @pipethrough_valve = {{valve}}
      end

      macro scope(path)
        if {{path}} != "/"
          @scope_path = {{path}}
        end

        {{yield}}
        @pipethrough_valve = nil
        @scope_path = ""
      end

      {% if flag?(:swagger) %}
        macro swagger(controllers)
          \{% for controller in controllers %}
            \{% for method in controller.resolve.methods %}
              \{% route_annotation = method.annotation(Grip::Annotations::Route) %}
              \{% controller_annotation = controller.resolve.annotation(Grip::Annotations::Controller) %}
              \{% if route_annotation && controller_annotation %}
                @swagger_handler.not_nil!.builder.add(
                  Swagger::Controller.new(
                    \{{ controller }}.to_s,
                    \{{ controller_annotation[:description] }},
                    [
                      Swagger::Action.new(
                        method: \{{route_annotation[:method]}} || "",
                        route: \{{route_annotation[:route]}} || "",
                        responses: \{{route_annotation[:responses]}} || [] of Swagger::Response,
                        request: \{{route_annotation[:request]}},
                        summary: \{{route_annotation[:summary]}},
                        parameters: \{{route_annotation[:parameters]}},
                        description: \{{route_annotation[:description]}},
                        authorization: \{{route_annotation[:authorization]}} || false,
                        deprecated: \{{route_annotation[:deprecated]}} || false
                      )
                    ]
                  )
                )
              \{% end %}
            \{% end %}
          \{% end %}
        end
      {% end %}

      {% if flag?(:minimal) || flag?(:minimal_with_logs) %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
            \{% if kwargs[:as] %}
              @http_handler.add_route(
                {{http_method}}.to_s.upcase,
                "#{@scope_path}#{\{{route}}}",
                \{{resource}}.new.as(Grip::Controllers::Base),
                @pipeline_handler.get(@pipethrough_valve),
                -> (context : HTTP::Server::Context) {
                  \{{ resource }}.new.as(\{{resource}}).\{{kwargs[:as].id}}(context)
                }
              )
            \{% else %}
              @http_handler.add_route(
                {{http_method}}.to_s.upcase,
                "#{@scope_path}#{\{{route}}}",
                \{{resource}}.new.as(Grip::Controllers::Base),
                @pipeline_handler.get(@pipethrough_valve),
                nil
              )
            \{% end %}
          end
        {% end %}

        macro error(error_code, resource)
          @exception_handler.handlers[\{{error_code}}] = \{{resource}}.new
        end
      {% elsif flag?(:logs) %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
              \{% if kwargs[:as] %}
                @http_handler.add_route(
                  {{http_method}}.to_s.upcase,
                  "#{@scope_path}#{\{{route}}}",
                  \{{resource}}.new.as(Grip::Controllers::Base),
                  @pipeline_handler.get(@pipethrough_valve),
                  -> (context : HTTP::Server::Context) {
                    \{{ resource }}.new.as(\{{resource}}).\{{kwargs[:as].id}}(context)
                  }
                )
              \{% else %}
                @http_handler.add_route(
                  {{http_method}}.to_s.upcase,
                  "#{@scope_path}#{\{{route}}}",
                  \{{resource}}.new.as(Grip::Controllers::Base),
                  @pipeline_handler.get(@pipethrough_valve),
                  nil
                )
              \{% end %}
            end
        {% end %}

        macro error(error_code, resource)
          @exception_handler.handlers[\{{error_code}}] = \{{resource}}.new
        end

        macro ws(route, resource, **kwargs)
          \{% if kwargs[:via] %}
            @websocket_handler.add_route("", "#{@scope_path}#{\{{route}}}", \{{ resource }}.new, @pipeline_handler.get(@pipethrough_valve), nil)
          \{% else %}
            @websocket_handler.add_route("", "#{@scope_path}#{\{{route}}}", \{{ resource }}.new, nil, nil)
          \{% end %}
        end
        macro error(error_code, resource)
          @exception_handler.handlers[\{{error_code}}] = \{{resource}}.new
        end

        macro filter(type, method, path, resource, **kwargs)
          \{% if kwargs[:via] %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, "#{@scope_path}#{\{{path}}}", \{{resource}}.new, @pipeline_handler.get(@pipethrough_valve))
          \{% else %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, "#{@scope_path}#{\{{path}}}", \{{resource}}.new, nil)
          \{% end %}
        end
      {% else %}
        {% for http_method in HTTP_METHODS %}
          macro {{http_method.id}}(route, resource, **kwargs)
              \{% if kwargs[:as] %}
                @http_handler.add_route(
                  {{http_method}}.to_s.upcase,
                  "#{@scope_path}#{\{{route}}}",
                  \{{resource}}.new.as(Grip::Controllers::Base),
                  @pipeline_handler.get(@pipethrough_valve),
                  -> (context : HTTP::Server::Context) {
                    \{{ resource }}.new.as(\{{resource}}).\{{kwargs[:as].id}}(context)
                  }
                )
              \{% else %}
                @http_handler.add_route(
                  {{http_method}}.to_s.upcase,
                  "#{@scope_path}#{\{{route}}}",
                  \{{resource}}.new.as(Grip::Controllers::Base),
                  @pipeline_handler.get(@pipethrough_valve),
                  nil
                )
              \{% end %}
            end
        {% end %}

        macro error(error_code, resource)
          @exception_handler.handlers[\{{error_code}}] = \{{resource}}.new
        end

        macro ws(route, resource, **kwargs)
          \{% if kwargs[:via] %}
            @websocket_handler.add_route("", "#{@scope_path}#{\{{route}}}", \{{ resource }}.new, @pipeline_handler.get(@pipethrough_valve), nil)
          \{% else %}
            @websocket_handler.add_route("", "#{@scope_path}#{\{{route}}}", \{{ resource }}.new, nil, nil)
          \{% end %}
        end

        macro filter(type, method, path, resource, **kwargs)
          \{% if kwargs[:via] %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, "#{@scope_path}#{\{{path}}}", \{{resource}}.new, @pipeline_handler.get(@pipethrough_valve))
          \{% else %}
            @filter_handler.\{{type.id}}(\{{method}}.to_s.upcase, "#{@scope_path}#{\{{path}}}", \{{resource}}.new, nil)
          \{% end %}
        end
      {% end %}
    end
  end
end
