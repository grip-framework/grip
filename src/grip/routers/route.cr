module Grip
  module Routers
    struct Route
      property method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controllers::Base, @via : Array(Symbol), @override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
        puts @via
      end

      def match_via_keyword(context : HTTP::Server::Context, pipeline_handler : Grip::Handlers::Pipeline) : HTTP::Server::Context
        puts @via
        call_through_pipeline(
          context,
          @via,
          pipeline_handler
        )

        context
      end

      def call_into_override(context : HTTP::Server::Context) : HTTP::Server::Context
        case @override
        when Proc(HTTP::Server::Context, HTTP::Server::Context)
          @override.not_nil!.call(context)
        when Nil
        end

        context
      end

      private def call_through_pipeline(context : HTTP::Server::Context, via : Symbol | Array(Symbol), pipeline_handler : Grip::Handlers::Pipeline) : HTTP::Server::Context
        pipes = pipeline_handler.get(via)
        pipes.each(&.call(context))
        context
      end
    end
  end
end
