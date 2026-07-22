module Grip
  module Macros
    module Dsl
      HTTP_METHODS = %i(get head post put delete connect options trace patch)

      macro pipe_through(valve)
        @valve = {{valve}}

        case {{valve}}
        when Symbol
          @valves.push({{valve}})
        end
      end

      macro scope
        %size = @valves.size

        {{yield}}

        @valves.pop(@valves.size - %size)
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

      macro pipeline(name, pipes)
        %pipeline_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::Pipeline) }

        if %pipeline_handler.nil?
          raise ::Exception.new("You need to add the Pipeline handler to use the `pipeline` macro")
        end

        %http_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::HTTP) }
        %server_sent_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::ServerSent) }
        %websocket_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::WebSocket) }

        if %http_handler.nil? && %server_sent_handler.nil? && %websocket_handler.nil?
          raise ::Exception.new("You need to add either HTTP, Server-Sent event, or WebSocket handlers to use the `pipeline` macro")
        end

        {{pipes}}.each do |pipe|
          %pipeline_handler
            .as(Grip::Handlers::Pipeline)
            .add_pipe({{name}}, pipe, %http_handler, %server_sent_handler, %websocket_handler)
        end
      end

      {% for http_method in HTTP_METHODS %}
        macro {{http_method.id}}(route, resource, **kwargs)
          %http_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::HTTP) }

          raise ::Exception.new("You need to add the HTTP handler to use the `{{http_method.id}}` macro") if %http_handler.nil?

          \{% if kwargs[:as] %}
            %http_handler
              .as(Grip::Handlers::Base)
              .add_route(
                {{http_method}}.to_s.upcase,
                [@scopes.join(), \{{route}}].join,
                \{{resource}}.instance.as(HTTP::Handler),
                @valves.clone(),
                ->(context : HTTP::Server::Context) { \{{resource}}.instance.as(\{{resource}}).\{{kwargs[:as].id}}(context) }
              )
          \{% else %}
            %http_handler
              .as(Grip::Handlers::Base)
              .add_route(
                {{http_method}}.to_s.upcase,
                [@scopes.join(), \{{route}}].join,
                \{{resource}}.instance.as(HTTP::Handler),
                @valves.clone(),
                nil
              )
          \{% end %}
        end
      {% end %}

      macro forward(route, resource, **kwargs)
        %http_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::HTTP) }

        raise ::Exception.new("You need to add the HTTP handler to use the `forward` macro") if %http_handler.nil?

        %http_handler
          .as(Grip::Handlers::HTTP)
          .add_route(
            "ALL",
            [@scopes.join(), {{route}}].join,
            {{resource}}.new({{kwargs.double_splat}}).as(HTTP::Handler),
            @valves.clone(),
            nil
          )
      end

      macro exception(exception, resource)
        %exception_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::Exception) }

        raise ::Exception.new("You need to add the Exception handler to use the `exception` macro") if %exception_handler.nil?

        %exception_handler
          .as(Grip::Handlers::Exception)
          .handlers[{{exception}}.name] = {{resource}}.instance
      end

      macro exceptions(exceptions, resource)
        %exception_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::Exception) }

        raise ::Exception.new("You need to add the Exception handler to use the `exceptions` macro") if %exception_handler.nil?

        {% for exception in exceptions %}
          %exception_handler
            .as(Grip::Handlers::Exception)
            .handlers[{{exception}}.name] = {{resource}}.instance
        {% end %}
      end

      macro sse(route, resource, **kwargs)
        %server_sent_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::ServerSent) }

        raise ::Exception.new("You need to add the server-side event handler to use the `sse` macro") if %server_sent_handler.nil?

        {% if kwargs[:as] %}
          %server_sent_handler
            .as(Grip::Handlers::Base)
            .add_route(
              "",
              [@scopes.join(), {{route}}].join,
              {{resource}}.instance,
              @valves.clone(),
              ->(context : HTTP::Server::Context) { {{resource}}.instance.as({{resource}}).{{kwargs[:as].id}}(context) }
            )
        {% else %}
          raise ::Exception.new("You need to specify the `as` keyword argument when using the `sse` macro")
        {% end %}
      end

      macro ws(route, resource, **kwargs)
        %websocket_handler = @handlers.find { |handler| handler.is_a?(Grip::Handlers::WebSocket) }

        raise ::Exception.new("You need to add the WebSocket handler to use the `websocket` macro") if %websocket_handler.nil?

        %websocket_handler
          .as(Grip::Handlers::WebSocket)
          .add_route(
            "",
            "#{@scopes.join()}#{{{route}}}",
            {{ resource }}.instance,
            @valves.clone(),
            nil
          )
      end
    end
  end
end
