module Grip
  module Parsers
    class ParameterBox
      URL_ENCODED_FORM = "application/x-www-form-urlencoded"
      APPLICATION_JSON = "application/json"
      MULTIPART_FORM   = "multipart/form-data"

      alias AllParamTypes = String? | Int64? | Float64? | Bool? | Hash(String, JSON::Any)? | Array(JSON::Any)?

      # Use class-level empty instances to avoid allocations
      EMPTY_STRING_HASH = {} of String => String
      EMPTY_PARAMS      = HTTP::Params.new({} of String => Array(String))
      EMPTY_JSON        = {} of String => AllParamTypes
      EMPTY_FILE        = {} of String => FileUpload

      @url : Hash(String, String)
      @query : HTTP::Params?
      @body : HTTP::Params?
      @json : Hash(String, AllParamTypes)?
      @file : Hash(String, FileUpload)?
      @request : HTTP::Request

      # Flags packed into single byte for cache efficiency
      @parsed_flags : UInt8 = 0_u8

      FLAG_URL   = 0x01_u8
      FLAG_QUERY = 0x02_u8
      FLAG_BODY  = 0x04_u8
      FLAG_JSON  = 0x08_u8
      FLAG_FILE  = 0x10_u8

      def initialize(@request : HTTP::Request, @url : Hash(String, String) = EMPTY_STRING_HASH)
      end

      @[AlwaysInline]
      private def parsed?(flag : UInt8) : Bool
        (@parsed_flags & flag) != 0
      end

      @[AlwaysInline]
      private def mark_parsed(flag : UInt8) : Nil
        @parsed_flags |= flag
      end

      # URL params - most frequently accessed, optimize heavily
      @[AlwaysInline]
      def url : Hash(String, String)
        return @url if parsed?(FLAG_URL)
        parse_url
        mark_parsed(FLAG_URL)
        @url
      end

      @[AlwaysInline]
      def query : HTTP::Params
        if parsed?(FLAG_QUERY)
          @query || EMPTY_PARAMS
        else
          parse_query
          mark_parsed(FLAG_QUERY)
          @query || EMPTY_PARAMS
        end
      end

      def body : HTTP::Params
        if parsed?(FLAG_BODY)
          @body || EMPTY_PARAMS
        else
          parse_body
          mark_parsed(FLAG_BODY)
          @body || EMPTY_PARAMS
        end
      end

      def json : Hash(String, AllParamTypes)
        if parsed?(FLAG_JSON)
          @json || EMPTY_JSON
        else
          parse_json
          mark_parsed(FLAG_JSON)
          @json || EMPTY_JSON
        end
      end

      def file : Hash(String, FileUpload)
        if parsed?(FLAG_FILE)
          @file || EMPTY_FILE
        else
          parse_file
          mark_parsed(FLAG_FILE)
          @file || EMPTY_FILE
        end
      end

      @[AlwaysInline]
      private def unescape_url_param(value : String) : String
        return value if value.empty?

        # Fast path: check if decoding is needed at all
        needs_decode = false
        value.each_byte do |byte|
          if byte === '%' || byte === '+'
            needs_decode = true
            break
          end
        end

        return value unless needs_decode
        URI.decode(value) rescue value
      end

      private def parse_url : Nil
        return if @url.empty?

        @url.each_key do |key|
          value = @url[key]
          decoded = unescape_url_param(value)
          @url[key] = decoded if decoded != value
        end
      end

      private def parse_query : Nil
        query_string = @request.query
        @query = if query_string && !query_string.empty?
                   HTTP::Params.parse(query_string)
                 else
                   EMPTY_PARAMS
                 end
      end

      private def parse_body : Nil
        content_type = @request.headers["Content-Type"]?

        unless content_type
          @body = EMPTY_PARAMS
          return
        end

        # Avoid starts_with? which creates substrings - use byte comparison
        if content_type_matches?(content_type, URL_ENCODED_FORM)
          @body = parse_part(@request.body)
        elsif content_type_matches?(content_type, MULTIPART_FORM)
          @body = EMPTY_PARAMS
          parse_file
        else
          @body = EMPTY_PARAMS
        end
      end

      @[AlwaysInline]
      private def content_type_matches?(content_type : String, expected : String) : Bool
        return false if content_type.bytesize < expected.bytesize

        expected.bytesize.times do |i|
          return false if content_type.byte_at(i) != expected.byte_at(i)
        end
        true
      end

      private def parse_file : Nil
        return if parsed?(FLAG_FILE)

        file_hash = {} of String => FileUpload

        HTTP::FormData.parse(@request) do |upload|
          next unless upload

          if upload.filename
            file_hash[upload.name] = FileUpload.new(upload)
          else
            @body ||= HTTP::Params.new({} of String => Array(String))
            if body = @body
              body.add(upload.name, upload.body.gets_to_end)
            end
          end
        end

        @file = file_hash
        mark_parsed(FLAG_FILE)
      end

      private def parse_json : Nil
        body_io = @request.body
        content_type = @request.headers["Content-Type"]?

        unless body_io && content_type && content_type_matches?(content_type, APPLICATION_JSON)
          @json = EMPTY_JSON
          return
        end

        body_str = body_io.gets_to_end

        if body_str.empty?
          @json = EMPTY_JSON
          return
        end

        json_hash = {} of String => AllParamTypes

        case json = JSON.parse(body_str).raw
        when Hash
          json.each do |key, value|
            json_hash[key] = value.raw
          end
        when Array
          json_hash["_json"] = json
        end

        @json = json_hash
      rescue JSON::ParseException
        @json = EMPTY_JSON
      end

      @[AlwaysInline]
      private def parse_part(part : IO?) : HTTP::Params
        if part
          content = part.gets_to_end
          content.empty? ? EMPTY_PARAMS : HTTP::Params.parse(content)
        else
          EMPTY_PARAMS
        end
      end

      @[AlwaysInline]
      private def parse_part(part : String?) : HTTP::Params
        part && !part.empty? ? HTTP::Params.parse(part) : EMPTY_PARAMS
      end
    end
  end
end
