require "spec"
require "../src/*"

include Grip

Spec.before_each do
  config = Grip.config
  config.env = "development"
end

Spec.after_each do
  Grip.config.clear
end
