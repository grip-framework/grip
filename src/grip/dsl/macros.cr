module Grip
  module Dsl
    module Macros
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          @pipeline_handler.not_nil!.add_pipe({{name}}, pipe)
        end
      end

      macro pipe_through(valve)
        case @pipethrough_valve
        when Array(Symbol)
          @pipethrough_valve.not_nil!.as(Array(Symbol)).push({{valve}})
        when Symbol
          @pipethrough_valve = [{{valve}}]
        else
          @pipethrough_valve = {{valve}}
        end
      end
    
      macro scope(path)
        scope_before = @scope_path

        if {{path}} != "/"
          @scope_path += {{path}}
        end

        {{yield}}
        @pipethrough_valve = nil
        @scope_path = scope_before
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

      {% for http_method in HTTP_METHODS %}
        macro {{http_method.id}}(route, resource, **kwargs)
          \{% if kwargs[:as] %}
            @http_handler.add_route(
              {{http_method}}.to_s.upcase,
              "#{@scope_path}#{\{{route}}}",
              \{{resource}}.new.as(Grip::Controllers::Base),
              @pipethrough_valve,
              -> (context : HTTP::Server::Context) {
                \{{ resource }}.new.as(\{{resource}}).\{{kwargs[:as].id}}(context)
              }
            )
          \{% else %}
            @http_handler.add_route(
              {{http_method}}.to_s.upcase,
              "#{@scope_path}#{\{{route}}}",
              \{{resource}}.new.as(Grip::Controllers::Base),
              @pipethrough_valve,
              nil
            )
          \{% end %}
        end
      {% end %}

      macro error(error_code, resource)
        @exception_handler.handlers[{{error_code}}] = {{resource}}.new
      end

      {% if flag?(:websocket) %}
        macro ws(route, resource, **kwargs)
          @websocket_handler.not_nil!.add_route("", "#{@scope_path}#{\{{route}}}", \{{ resource }}.new, @pipethrough_valve, nil)
        end
      {% end %}
    end
  end
end
