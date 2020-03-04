module Grip
  module Pipe
    class PoweredByGrip < Base
      def call(context : HTTP::Server::Context)
        context.response.headers["X-Powered-By"] = "Grip"
      end
    end
  end
end
