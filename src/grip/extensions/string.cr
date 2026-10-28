module Grip
  module Extensions
    module String
      def str?
        self.is_a? String
      end

      # email validation
      def email?
        !!match(/^[_]*([a-z0-9]+(\.|_*)?)+@([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$/)
      end

      # domain validation
      def domain?
        !!match(/^([a-z][a-z0-9-]+(\.|-*\.))+[a-z]{2,6}$/)
      end

      # url validation
      def url?
        !!match(/^(http(s)?(:\/\/))?(www\.)?[a-zA-Z0-9-_\.]+(\.[a-zA-Z0-9]{2,})([-a-zA-Z0-9:%_\+.~#?&\/\/=]*)/)
      end

      # ip v4 validation
      def ipv4?
        !!match(/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/)
      end

      # ip v6 validation
      def ipv6?
        !!match(/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})$/)
      end

      # mac address validation
      def mac_address?
        !!match(/^([0-9a-fA-F][0-9a-fA-F]:){5}([0-9a-fA-F][0-9a-fA-F])$/)
      end

      # hex color validation
      def hex_color?
        !!match(/^#?([0-9A-F]{3}|[0-9A-F]{6})$/i)
      end

      # hexadecimal validation
      def hex?
        !!match(/^(0x)?[0-9A-F]+$/i)
      end

      # alpha characters validation
      def alpha?(locale = "en-US")
        !!match(Support::LocaleFormat::ALPHA[locale])
      end

      # numeric characters validation
      def numeric?
        !!match(/^([0-9]+)$/)
      end

      # alpha numeric characters validation
      def alphanum?(locale = "en-US")
        !!match(Support::LocaleFormat::ALPHA_NUM[locale])
      end

      # md5 validation
      def md5?
        !!match(/^[a-f0-9]{32}$/)
      end

      # base64 validation
      def base64?
        !!match(/^[a-zA-Z0-9+\/]+={0,2}$/) && (size % 4 === 0)
      end

      # slug validation
      def slug?
        !!match(/^([a-zA-Z0-9_-]+)$/)
      end

      # lower case validation
      def lower?
        downcase === self
      end

      # upper case validation
      def upper?
        upcase === self
      end

      # credit card validation
      def credit_card?
        !!match(/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|(222[1-9]|22[3-9][0-9]|2[3-6][0-9]{2}|27[01][0-9]|2720)[0-9]{12}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\d{3})\d{11})|62[0-9]{14}$/)
      end

      # phone number validation
      def phone?(locale = "en-US")
        !!match(Support::LocaleFormat::PHONE_FORMAT[locale])
      end

      def excludes?(value)
        !!includes?(value)
      end

      # time string validation
      def time_string?
        !!match(/^(2[0-3]|[01]?[0-9]):([0-5]?[0-9]):([0-5]?[0-9])$/)
      end
    end
  end
end
