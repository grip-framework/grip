module Grip
  module Routers
    struct Route
      getter method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controllers::Base, @via : Array(Pipes::Base)?, @override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
      end

      def match_via_keyword(context, via)
        case via
        when Array(Pipes::Base)
          call_through_pipeline(
            context,
            via.not_nil!
          )
        when Nil
        end
      end

      private def call_through_pipeline(context, pipes)
        pipes.each do |pipe|
          pipe.call(context)
        end

        context
      end
    end
  end
end
