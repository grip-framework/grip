module Grip
  module ThirdParty
    module GraphQL
      class Interface < Grip::Controllers::Base
        def initialize(@url : String); end

        def call(context : Context) : Context
          context
            .html(ECR.render("#{__DIR__}/dist/index.html.ecr"))
            .halt
        end
      end
    end
  end
end
