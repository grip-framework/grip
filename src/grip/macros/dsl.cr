module Grip
  module Macros
    module Dsl
      HTTP_METHODS = %i(get post put patch delete options head)

      macro pipeline(name, pipes)
        {{pipes}}.each do |pipe|
          @pipeline_handler.add_pipe({{name}}, pipe)
        end
      end

      macro pipe_through(valve)
        @valve = {{valve}}
        case {{valve}}
        when Symbol
          @valves.push({{valve}})
        end
      end

      macro scope(path)
        %size = @valves.size

        if {{path}} != "/"
          @scopes.push({{path}})
        end

        {{yield}}

        @valves.pop(@valves.size - %size)

        if {{path}} != "/"
          @scopes.pop()
        end
      end

      {% for http_method in HTTP_METHODS %}
        macro {{http_method.id}}(route, resource, **kwargs)
          \{% if kwargs[:as] %}
            @http_handler.add_route({{http_method}}.to_s.upcase, [@scopes.join(), \{{route}}].join, \{{resource}}.instance.as(HTTP::Handler), @valves.clone(), ->(context : HTTP::Server::Context) { \{{resource}}.instance.as(\{{resource}}).\{{kwargs[:as].id}}(context) })
          \{% else %}
            @http_handler.add_route({{http_method}}.to_s.upcase, [@scopes.join(), \{{route}}].join, \{{resource}}.instance.as(HTTP::Handler), @valves.clone(), nil)
          \{% end %}
        end
      {% end %}

      macro forward(route, resource, **kwargs)
        @http_handler.add_route("ALL", [@scopes.join(), {{route}}].join, {{resource}}.new({{**kwargs}}).as(HTTP::Handler), @valves.clone(), nil)
      end

      macro exception(exception, resource)
        @exception_handler.handlers[{{exception}}.name] = {{resource}}.instance
      end

      macro exceptions(exceptions, resource)
        {% for exception in exceptions %}
          @exception_handler.handlers[{{exception}}.name] = {{resource}}.instance
        {% end %}
      end

      macro ws(route, resource, **kwargs)
        @websocket_handler.add_route("", "#{@scopes.join()}#{{{route}}}", {{ resource }}.new, @valves.clone(), nil)
      end
    end
  end
end
