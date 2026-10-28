module Grip
  module Middleware
    class CrossSiteRequestForgery
      include HTTP::Handler

      CHECK_METHODS = %w[PUT POST PATCH DELETE]
      HEADER_KEY    = "X-CSRF-Token"
      PARAM_KEY     = "_csrf"
      COOKIE_KEY    = "csrf_token"
      TOKEN_LENGTH  = 32

      class_property secret : String = ""
      class_property? secure : Bool = true

      def initialize(secret : String, secure : Bool = true)
        self.class.secret = secret
        self.class.secure = secure
      end

      # Rejects unsafe requests whose submitted token doesn't match the cookie token
      def call(context : HTTP::Server::Context)
        if CHECK_METHODS.includes?(context.request.method)
          raw = self.class.existing_token(context)
          sent = request_token(context.request)

          unless raw && sent && self.class.valid?(raw, sent)
            raise Grip::Exceptions::Forbidden.new("CSRF check failed.")
          end
        end

        context
      end

      # Masked token, different on every call; safe to embed in HTML
      def self.token(context : HTTP::Server::Context) : String
        mask(raw_token(context))
      end

      # Hidden input for HTML forms
      def self.tag(context : HTTP::Server::Context) : String
        %Q(<input type="hidden" name="#{PARAM_KEY}" value="#{token(context)}" />)
      end

      # Meta tag so JavaScript can read the token and send it as a header
      def self.metatag(context : HTTP::Server::Context) : String
        %Q(<meta name="#{PARAM_KEY}" content="#{token(context)}" />)
      end

      # Returns the raw token from a valid signed cookie, or nil
      def self.existing_token(context) : Bytes?
        value = context.request.cookies[COOKIE_KEY]?.try(&.value)
        value ? verify(value) : nil
      end

      # Returns the raw token, issuing a new cookie if the client has none
      def self.raw_token(context) : Bytes
        existing_token(context) || begin
          bytes = Random::Secure.random_bytes(TOKEN_LENGTH)

          cookie = HTTP::Cookie.new(
            name: COOKIE_KEY,
            value: sign(bytes),
            path: "/",
            secure: secure,
            http_only: true,
            samesite: HTTP::Cookie::SameSite::Lax
          )

          context.response.cookies << cookie
          context.request.cookies << cookie

          bytes
        end
      end

      # Encodes the token and appends an HMAC so the server can detect forgery
      private def self.sign(bytes : Bytes) : String
        encoded = Base64.urlsafe_encode(bytes)
        "#{encoded}.#{OpenSSL::HMAC.hexdigest(:sha256, secret, encoded)}"
      end

      # Checks the HMAC in constant time and returns the decoded token, or nil
      private def self.verify(value : String) : Bytes?
        encoded, _, mac = value.partition('.')

        return if mac.empty?

        expected = OpenSSL::HMAC.hexdigest(:sha256, secret, encoded)
        return unless Crypto::Subtle.constant_time_compare(mac, expected)

        bytes = Base64.decode(encoded)
        bytes.size == TOKEN_LENGTH ? bytes : nil
      rescue Base64::Error
        nil
      end

      # Unmasks the submitted token and compares it to the raw token in constant time
      def self.valid?(raw : Bytes, sent : String) : Bool
        decoded = Base64.decode(sent)
        return false unless decoded.size == TOKEN_LENGTH * 2

        Crypto::Subtle.constant_time_compare(unmask(decoded), raw)
      rescue Base64::Error
        false
      end

      # XORs the raw token with a random one-time pad (pad + ciphertext), mitigating BREACH
      def self.mask(raw : Bytes) : String
        pad = Random::Secure.random_bytes(TOKEN_LENGTH)
        encrypted = Bytes.new(TOKEN_LENGTH) { |i| raw[i] ^ pad[i] }

        io = IO::Memory.new
        io.write(pad)
        io.write(encrypted)

        Base64.urlsafe_encode(io.to_slice)
      end

      # Reverses mask by XORing the ciphertext with the pad that prefixes it
      def self.unmask(masked : Bytes) : Bytes
        pad = masked[0, TOKEN_LENGTH]
        encrypted = masked[TOKEN_LENGTH, TOKEN_LENGTH]

        Bytes.new(TOKEN_LENGTH) { |i| encrypted[i] ^ pad[i] }
      end

      # Prefers the header (AJAX) and falls back to the form field
      private def request_token(request : HTTP::Request) : String?
        request.headers[HEADER_KEY]? || form_token(request)
      end

      # Reads the form field and restores the body so controllers can still parse it
      private def form_token(request : HTTP::Request) : String?
        return unless request.headers["Content-Type"]?.try(&.starts_with?("application/x-www-form-urlencoded"))

        body = request.body.try(&.gets_to_end) || ""
        request.body = IO::Memory.new(body)

        URI::Params.parse(body)[PARAM_KEY]?
      end
    end
  end
end
