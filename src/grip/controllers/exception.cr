module Grip
  module Controllers
    class Exception < Base
      macro inherited
        macro finished
          @@instance = new

          def self.instance
            @@instance
          end
        end
      end

      def call(context : Context) : Context
        context.html(context.exception)
      end
    end
  end
end
