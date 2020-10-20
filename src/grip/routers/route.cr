module Grip
  module Routers
    struct Route
      alias Context = HTTP::Server::Context
      getter method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controllers::Base, @via : Array(Pipes::Base)?, @override : Proc(Context, Context)?)
      end

      def match_via_keyword(context : Context) : Context
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

      def call_into_override(context : Context) : Context
        case @override
        when Proc(Context, Context)
          @override.not_nil!.call(context)
        when Nil
        end

        context
      end

      private def call_through_pipeline(context : Context, pipes) : Context
        pipes.each do |pipe|
          pipe.call(context)
        end

        context
      end
    end
  end
end
