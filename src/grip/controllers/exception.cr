module Grip
  module Controllers
    class Exception < Base
      include Helpers::Singleton

      def call(context : Context) : Context
        context.html(context.exception)
      end
    end
  end
end
