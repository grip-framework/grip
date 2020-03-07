module Grip
  module Pipe
    class Basic < Base
      BASIC                 = "Basic"
      AUTH                  = "Authorization"
      HEADER_LOGIN_REQUIRED = "Basic realm=\"Login Required\""

      def initialize(@credentials : Credentials)
      end

      # backward compatibility
      def initialize(username : String, password : String)
        initialize({username => password})
      end

      def initialize(hash : Hash(String, String))
        initialize(Credentials.new(hash))
      end

      def call(context)
        if context.request.headers[AUTH]?
          if value = context.request.headers[AUTH]
            if value.size > 0 && value.starts_with?(BASIC)
              if username = authorize?(value)
                context.basic_payload = username
              else
                raise Grip::Exceptions::Unauthorized.new(context)
              end
            else
              context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
              raise Grip::Exceptions::Unauthorized.new(context)
            end
          else
            context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
            raise Grip::Exceptions::Unauthorized.new(context)
          end
        else
          context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
          raise Grip::Exceptions::Unauthorized.new(context)
        end
      end

      def authorize?(value) : String?
        username, password = Base64.decode_string(value[BASIC.size + 1..-1]).split(":")
        @credentials.authorize?(username, password)
      end
    end
  end
end
