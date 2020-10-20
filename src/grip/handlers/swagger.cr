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
        if context.request.path == @path
          # ameba:disable Lint/UselessAssign
          title = "API Documentation"

          # ameba:disable Lint/UselessAssign
          openapi_url = "/swagger.json"

          context
            .html(
              ECR.render("./lib/swagger/src/swagger/http/views/swagger.ecr")
            )
        elsif context.request.path == "/swagger.json"
          context
            .json(
              @builder.built
            )
        else
          call_next(context)
        end
      end
    end
  end
end
