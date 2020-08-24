module Grip
  module Routers
    struct Route
      getter method, path, handler, override, via

      def initialize(@method : String, @path : String, @handler : Grip::Controllers::Base, @via : Symbol? | Array(Symbol)?, @override : Proc(HTTP::Server::Context, HTTP::Server::Context)?)
      end

      def match_via_keyword(context, via)
        case via
        when Symbol
          call_through_pipeline(
            context,
            via.not_nil!.as(Symbol)
          )
        when Array(Symbol)
          via
            .not_nil!
            .as(
              Array(Symbol)
            )
            .each do |_via|
              call_through_pipeline(
                context,
                _via
              )
            end
        when Nil
        end
      end

      private def call_through_pipeline(context, via)
        Grip::Handlers::Pipeline::INSTANCE.pipeline[via].each do |pipe|
          pipe.call(context)
        end
      end
    end
  end
end
