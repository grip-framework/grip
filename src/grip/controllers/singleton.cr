module Grip
  module Controllers
    module Singleton
      macro included
        macro inherited
          @@instance = new

          def self.instance
            @@instance
          end
        end
      end
    end
  end
end
