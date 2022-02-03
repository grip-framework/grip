module Grip
  module Controllers
    abstract class Exception < Base
      macro inherited
        @@instance = new

        def self.instance
          @@instance
        end
      end

      abstract def call(context : Context) : Context
    end
  end
end
