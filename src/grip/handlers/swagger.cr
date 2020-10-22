module Grip
  module Handlers
    class Swagger
      include HTTP::Handler
      property builder : ::Swagger::Builder

      property title : String = "API Documentation"
      property version : String = "0.1.0"
      property description : String = ""
      property authorizations : Array(::Swagger::Authorization)?

      property path : String = "/docs"

      def initialize(@path : String, @title : String, @version : String, @description : String, @authorizations : Array(::Swagger::Authorization)?)
        @builder = ::Swagger::Builder.new(
          title: @title,
          version: @version,
          description: @description,
          authorizations: @authorizations
        )
      end

      def call(context : HTTP::Server::Context)
        case context.request.path
        when @path
          # ameba:disable Lint/UselessAssign
          title = "API Documentation"

          # ameba:disable Lint/UselessAssign
          openapi_url = "/swagger.json"

          context.response.headers.merge!({"Content-Type" => "text/html; charset=UTF-8"})
          context.response.print(ECR.render("./lib/swagger/src/swagger/http/views/swagger.ecr"))
          context
        when "/swagger.json"
          context.response.headers.merge!({"Content-Type" => "application/json; charset=UTF-8"})
          context.response.print(@builder.built.to_json)
          context
        else
          call_next(context)
        end
      end
    end
  end
end
