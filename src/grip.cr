require "http"
require "http/web_socket"
require "json"
require "uri"
require "radix"
require "base64"
require "uuid"
require "crypto/subtle"
require "exceptions"
require "pipes"
require "exception_page"
require "swagger"

{% if flag?(:with_openssl) %}
  require "openssl/sha1"
{% else %}
  require "digest/sha1"
{% end %}

require "./grip/annotations/*"
require "./grip/minuscule/*"
require "./grip/parsers/*"
require "./grip/dsl/*"
require "./grip/extensions/*"
require "./grip/handlers/*"
require "./grip/controllers/*"
require "./grip/routers/route"
require "./grip/routers/*"
require "./grip/*"

module Grip; end
