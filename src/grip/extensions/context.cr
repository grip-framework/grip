module Grip
  module Extensions
    module Context
      property client_ip : ::Socket::IPAddress?
      property exception : ::Exception?
      property parameters : ::Grip::Parsers::ParameterBox?

      @stream : ::Grip::ServerSent::Stream?

      # Lazy-initializes the stream with custom backpressure capacity
      @[AlwaysInline]
      def stream(
        capacity : Int32 = 100,
        strategy : ::Grip::ServerSent::Strategy = ::Grip::ServerSent::Strategy::DropOldest
      ) : ::Grip::ServerSent::Stream
        @stream ||= ::Grip::ServerSent::Stream.new(
          self,
          capacity: capacity,
          strategy: strategy
        )
      end

      # Nil-safe accessor for checking if a stream is already active
      @[AlwaysInline]
      def stream? : ::Grip::ServerSent::Stream?
        @stream
      end

      # Deletes a request header by key.
      # Returns self for method chaining.
      @[AlwaysInline]
      def delete_req_header(key : ::String) : self
        @request.headers.delete(key)
        self
      end

      # Deletes a response header by key.
      # Returns self for method chaining.
      @[AlwaysInline]
      def delete_resp_header(key : ::String) : self
        @response.headers.delete(key)
        self
      end

      # Gets a request header by key, raises KeyError if not found.
      # Use `get_req_header?` for a nil-safe alternative.
      @[AlwaysInline]
      def get_req_header(key : ::String) : ::String
        @request.headers[key]
      end

      # Gets a request header by key, returns nil if not found.
      @[AlwaysInline]
      def get_req_header?(key : ::String) : ::String?
        @request.headers[key]?
      end

      # Gets a cookie from the request by key, returns nil if not found.
      @[AlwaysInline]
      def get_req_cookie(key : ::String) : ::HTTP::Cookie?
        @request.cookies[key]?
      end

      # Gets a response header by key, raises KeyError if not found.
      @[AlwaysInline]
      def get_resp_header(key : ::String) : ::String
        @response.headers[key]
      end

      # Halts endpoint execution by closing the response.
      # Returns self for method chaining.
      @[AlwaysInline]
      def halt : self
        @response.close
        self
      end

      # Merges the given headers into the response headers.
      # Returns self for method chaining.
      @[AlwaysInline]
      def merge_resp_headers(headers : ::Hash(::String, ::String)) : self
        @response.headers.merge!(headers)
        self
      end

      # Assigns a request header with the given key and value.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_req_header(key : ::String, value : ::String) : self
        @request.headers[key] = value
        self
      end

      # Assigns a response header with the given key and value.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_resp_header(key : ::String, value : ::String) : self
        @response.headers[key] = value
        self
      end

      # Sets a response cookie with the given cookie object.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_resp_cookie(cookie : ::HTTP::Cookie) : self
        @response.cookies[cookie.name] = cookie
        self
      end

      # Sets a response cookie with the given key and value as a string.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_resp_cookie(key : ::String, value : ::String) : self
        @response.cookies[key] = value
        self
      end

      # Assigns the response status code.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_status(status_code : ::HTTP::Status = ::HTTP::Status::OK) : self
        @response.status_code = status_code.to_i
        self
      end

      # Assigns the response status code.
      # Returns self for method chaining.
      @[AlwaysInline]
      def put_status(status_code : Int32 = 200) : self
        put_status(::HTTP::Status.new(status_code))
      end

      # Sends a response with the given content and a status code of OK.
      # Returns self for method chaining.
      @[AlwaysInline]
      def send_resp(content : ::String) : self
        @response.print(content)
        self
      end

      # Sends a file as the response.
      # `path` must point to an existing file.
      # `mime_type` can be specified, otherwise inferred from the file extension.
      # `gzip_enabled` enables gzip compression if supported.
      # Returns self for method chaining.
      def send_file(
        path : ::String,
        mime_type : ::String? = nil,
        gzip_enabled : Bool = false
      ) : self
        ::Grip::Helpers::FileDownload.send_file(self, path, mime_type, gzip_enabled)
        self
      end

      # Sends a response with content formatted as JSON.
      # Sets the Content-Type header to the specified `content_type`.
      # Returns self for method chaining.
      @[AlwaysInline]
      def json(content, content_type : ::String = "application/json") : self
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content.to_json)
        self
      end

      # Sends a response with content formatted as HTML.
      # Sets the Content-Type header to the specified `content_type`.
      # Returns self for method chaining.
      @[AlwaysInline]
      def html(content : ::String, content_type : ::String = "text/html; charset=UTF-8") : self
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Sends a response with content formatted as plain text.
      # Sets the Content-Type header to the specified `content_type`.
      # Returns self for method chaining.
      @[AlwaysInline]
      def text(content : ::String, content_type : ::String = "text/plain; charset=UTF-8") : self
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Sends a response with content as binary data.
      # Sets the Content-Type header to the specified `content_type`.
      # Returns self for method chaining.
      @[AlwaysInline]
      def binary(content : ::String | Bytes, content_type : ::String = "application/octet-stream") : self
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Fetches parsed JSON parameters from the request.
      # Returns an empty hash if no parameters are available.
      @[AlwaysInline]
      def fetch_json_params : ::Hash(::String, ::Grip::Parsers::ParameterBox::AllParamTypes)
        @parameters
          .try(&.json)
          .try(&.as(::Hash(::String, ::Grip::Parsers::ParameterBox::AllParamTypes))) || {} of ::String => ::Grip::Parsers::ParameterBox::AllParamTypes
      end

      # Fetches parsed GET query parameters from the request.
      # Returns an empty hash if no parameters are available.
      @[AlwaysInline]
      def fetch_query_params : ::URI::Params
        @parameters.try(&.query) || ::URI::Params.new
      end

      # Fetches parsed URL-encoded body parameters from the request.
      # Returns an empty hash if no parameters are available.
      @[AlwaysInline]
      def fetch_body_params : ::URI::Params
        @parameters.try(&.body) || ::URI::Params.new
      end

      # Fetches parsed multipart file data from the request.
      # Returns an empty hash if no parameters are available.
      @[AlwaysInline]
      def fetch_file_params : ::Hash(::String, ::Grip::Parsers::FileUpload)
        @parameters.try(&.file) || {} of ::String => ::Grip::Parsers::FileUpload
      end

      # Fetches parsed URL path parameters from the request.
      # Returns an empty hash if no parameters are available.
      @[AlwaysInline]
      def fetch_path_params : ::Hash(::String, ::String)
        @parameters.try(&.url) || {} of ::String => ::String
      end

      # Redirects the response to the specified URL with a given status code.
      # Returns self for method chaining.
      @[AlwaysInline]
      def redirect(url : ::String = "/", status_code : ::HTTP::Status = ::HTTP::Status::FOUND) : self
        @response.headers["Location"] = url
        @response.status_code = status_code.to_i
        self
      end

      @[AlwaysInline]
      def redirect(url : ::String = "/", status_code : Int32 = 302) : self
        redirect(url, ::HTTP::Status.new(status_code))
      end

      # Executes a block with self as the context.
      # Returns the result of the block.
      def exec(&)
        with self yield
      end
    end
  end
end
