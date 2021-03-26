module Grip
  module ThirdParty
    module GraphQL
      class Processor < Grip::Controllers::Base
        def initialize(@schema : ::GraphQL::Schema::Schema)
        end

        def call(context : Context) : Context
          query =
            context
              .fetch_json_params
              .["query"].as(String)

          variables =
            context
              .fetch_json_params
              .["variables"]?.as(Hash(String, JSON::Any)?)

          operation_name =
            context
              .fetch_json_params
              .["operationName"]?.as(String?)

          context
            .json(@schema.execute(query, variables, operation_name))
            .halt
        end
      end
    end
  end
end
