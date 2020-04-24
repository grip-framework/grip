module Grip
  module Pipe
    class Log < Base
      def call(context : HTTP::Server::Context)
        STDOUT.print "#{Time.utc} #{context.response.status_code} #{context.request.method} #{context.request.resource}\n"
        STDOUT.flush
      end
    end
  end
end
