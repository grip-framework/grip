require "http"
require "json"
require "uri"
require "base64"
require "radix"
require "redis"
require "uuid"

{% if flag?(:without_openssl) %}
  require "digest/sha1"
{% else %}
  require "openssl/sha1"
{% end %}

require "./grip/dsl/*"
require "./grip/extensions/*"
require "./grip/core/*"
require "./grip/pipe/*"
require "./grip/controller/*"
require "./grip/exceptions/*"
require "./grip/router/*"
require "./grip/*"

module Grip; end
