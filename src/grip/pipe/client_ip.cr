module Grip
  module Pipe
    class ClientIp < Base
      def initialize(header : String = "X-Forwarded-For")
        @headers = [header]
      end

      def initialize(@headers : Array(String))
      end

      def call(context : HTTP::Server::Context)
        @headers.each do |header|
          if addresses = context.request.headers.get?(header)
            context.client_ip = Socket::IPAddress.new(addresses[0], 0)
          end
        end
      end
    end
  end
end
