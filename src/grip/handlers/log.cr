module Grip
  module Handlers
    class Log < Base
      def add_route(
        verb : String,
        path : String,
        handler : ::HTTP::Handler,
        via : Symbol? | Array(Symbol)? = nil,
        override : Proc(::HTTP::Server::Context, ::HTTP::Server::Context)? = nil
      ) : Nil
      end

      def find_route(verb : String, path : String) : Radix::Result(Route)
        Radix::Result(Route).new
      end

      @[AlwaysInline]
      def call(context : ::HTTP::Server::Context) : ::HTTP::Server::Context
        start = Time.monotonic
        call_next(context)
        elapsed = Time.monotonic - start

        log_request(context, elapsed)
        context
      end

      @[AlwaysInline]
      private def log_request(context : ::HTTP::Server::Context, elapsed : Time::Span) : Nil
        ::Log.info do
          String.build(64) do |io|
            io << context.response.status_code
            io << ' '
            io << context.request.method
            io << ' '
            io << context.request.resource
            io << ' '
            format_elapsed_time(io, elapsed)
          end
        end
      end

      @[AlwaysInline]
      private def format_elapsed_time(io : IO, elapsed : Time::Span) : Nil
        millis = elapsed.total_milliseconds

        if millis >= 1
          io << millis.round(2)
          io << "ms"
        else
          io << (millis * 1000).round(2)
          io << "µs"
        end
      end
    end
  end
end
