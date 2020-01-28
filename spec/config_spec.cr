require "./spec_helper"

describe "Config" do
  it "sets default port to 3000" do
    Grip::Config.new.port.should eq 3000
  end

  it "sets default environment to development" do
    Grip::Config.new.env.should eq "development"
  end

  it "sets environment to production" do
    config = Grip.config
    config.env = "production"
    config.env.should eq "production"
  end

  it "sets default powered_by_header to true" do
    Grip::Config.new.powered_by_header.should be_true
  end

  it "sets host binding" do
    config = Grip.config
    config.host_binding = "127.0.0.1"
    config.host_binding.should eq "127.0.0.1"
  end

  it "adds custom options" do
    config = Grip.config
    ARGV.push("--test")
    ARGV.push("FOOBAR")
    test_option = nil

    config.extra_options do |parser|
      parser.on("--test TEST_OPTION", "Test an option") do |opt|
        test_option = opt
      end
    end
    Grip::CLI.new ARGV
    test_option.should eq("FOOBAR")
  end

  it "gets the version from shards.yml" do
    Grip::VERSION.should_not be("")
  end
end
