module Grip
  module Controllers
    class Http < Base
      macro inherited
        macro finished
          @@instance = new

          def self.instance
            @@instance
          end
        end
      end

      def get(context : Context) : Context
        context
          .halt
      end

      def post(context : Context) : Context
        context
          .halt
      end

      def put(context : Context) : Context
        context
          .halt
      end

      def patch(context : Context) : Context
        context
          .halt
      end

      def delete(context : Context) : Context
        context
          .halt
      end

      def options(context : Context) : Context
        context
          .halt
      end

      def head(context : Context) : Context
        context
          .halt
      end

      def call(context : Context) : Context
        case context.request.method
        when "GET"
          get(context)
        when "POST"
          post(context)
        when "PUT"
          put(context)
        when "PATCH"
          patch(context)
        when "DELETE"
          delete(context)
        when "OPTIONS"
          options(context)
        when "HEAD"
          head(context)
        else
          raise Exceptions::MethodNotAllowed.new
        end
      end
    end
  end
end
