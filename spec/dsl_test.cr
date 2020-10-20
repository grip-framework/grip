describe "Grip::Dsl::Macros" do
  it "Tests the HTTP verb macro" do
    app = HttpApplication.new
    app.run
  end

  it "Tests the WebSocket verb macro" do
    app = WebSocketApplication.new
    app.run
  end

  it "Tests the pipeline, pipe_through and scope macro" do
    app = PipelineApplication.new
    app.run
  end
end
