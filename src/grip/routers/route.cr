module Grip
  module Routers
    struct Route
      getter method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controllers::Base, @via : Array(Pipes::Base)?, @override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
      end

      def match_via_keyword(context : HTTP::Server::Context) : HTTP::Server::Context
        case @via
        when Array(Pipes::Base)
          call_through_pipeline(
            context,
            via.not_nil!
          )
        when Nil
        end

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

      private def call_through_pipeline(context : HTTP::Server::Context, pipes) : HTTP::Server::Context
        pipes.each do |pipe|
          pipe.call(context)
        end

        context
      end
    end
  end
end
