module Grip
  module Pipe
    class Basic < Base
      BASIC                 = "Basic"
      AUTH                  = "Authorization"
      AUTH_MESSAGE          = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
      HEADER_LOGIN_REQUIRED = "Basic realm=\"Login Required\""
    
      def initialize(@credentials : Credentials)
      end
    
      # backward compatibility
      def initialize(username : String, password : String)
        initialize({ username => password })
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
            end
          end
        else
          headers = HTTP::Headers.new
          context.response.status_code = 401
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