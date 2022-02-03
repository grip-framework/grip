module Grip
  module Controllers
    class Swagger < Grip::Controllers::Base
      macro inherited
        @@instance = new

        def self.instance
          @@instance
        end
      end

      property document : ::Swagger::Builder
      property base_path : String

      def initialize(@document : ::Swagger::Builder, @base_path : String = "/api/swagger"); end

      def call(context : Context) : Context
        case context.request.path.includes?(".json")
        when false
          title = "Swagger UI"
          openapi_url = "#{base_path}/swagger.json"

          context
            .put_resp_header("Content-Type", "text/html; charset=UTF-8")
            .send_resp(ECR.render("./lib/swagger/src/swagger/http/views/swagger.ecr"))
            .halt
        when true
          context
            .json(@document.built)
            .halt
        else
          raise Grip::Exceptions::NotFound.new
        end
      end
    end
  end
end
