require "./spec_helper"

describe "Grip::Handlers::Swagger" do
  it "Tests the swagger macro" do
    app = SwaggerApplication.new
    app.run
  end
end
