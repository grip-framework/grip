require "./spec_helper"

private def run(code)
  code = <<-CR
    require "./src/grip"
    #{code}
    CR
  String.build do |stdout|
    stderr = String.build do |io|
      Process.new("crystal", ["eval"], input: IO::Memory.new(code), output: stdout, error: io).wait
    end
    fail(stderr) unless stderr.empty?
  end
end

describe "Run" do
  it "runs a code block after starting" do
    run(<<-CR).should_not be("")
      Grip.config.env = "test"
      Grip.run do
        puts "started"
        Grip.stop
        puts "stopped"
      end
      CR
  end

  it "runs without a block being specified" do
    run(<<-CR).should_not be("")
      Grip.config.env = "test"
      Grip.run
      puts Grip.config.running
      CR
  end

  it "allows custom HTTP::Server bind" do
    run(<<-CR).should_not be("")
      Grip.config.env = "test"
      Grip.run do |config|
        server = config.server.not_nil!
        server.bind_tcp "127.0.0.1", 3000, reuse_port: true
        server.bind_tcp "0.0.0.0", 3001, reuse_port: true
      end
      CR
  end
end
