module Grip
  module Pipe
    class Jwt < Base
      BEARER = "Bearer"
      AUTH   = "Authorization"

      def initialize(
        @secret_key : String = ENV["GRIP_JWT_SECRET"],
        claims : Hash(Symbol, String?) = {:aud => nil, :iss => nil, :sub => nil},
        @algorithm : JWT::Algorithm = JWT::Algorithm::HS256
      )
        @claims = NamedTuple(aud: String?, iss: String?, sub: String?).from(claims)
      end

      def self.encode_and_sign(
        data : Hash,
        secret_key : String = ENV["GRIP_JWT_SECRET"],
        algorithm : JWT::Algorithm = JWT::Algorithm::HS256
      )
        JWT.encode(data, secret_key, algorithm)
      end

      def self.decode_and_verify(
        data : String,
        claims : Hash = {:aud => nil, :iss => nil, :sub => nil},
        secret_key : String = ENV["GRIP_JWT_SECRET"],
        algorithm : JWT::Algorithm = JWT::Algorithm::HS256
      )
        JWT.decode(data, secret_key, algorithm, **NamedTuple(aud: String?, iss: String?, sub: String?).from(claims))
      end

      def call(context)
        if context.request.headers[AUTH]?
          if value = context.request.headers[AUTH]
            if value.size > 0 && value.starts_with?(BEARER)
              begin
                payload, _ = JWT.decode(value[BEARER.size + 1..], @secret_key, @algorithm, **@claims)
                context.jwt_payload = payload
              rescue exception
                context.jwt_payload = nil
                raise Grip::Exceptions::Unauthorized.new(context)
              end
            else
              raise Grip::Exceptions::Unauthorized.new(context)
            end
          else
            raise Grip::Exceptions::Unauthorized.new(context)
          end
        else
          raise Grip::Exceptions::Unauthorized.new(context)
        end
      end
    end
  end
end
