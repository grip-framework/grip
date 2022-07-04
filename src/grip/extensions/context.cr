module Grip
  module Extensions
    module Context
      property exception : Exception?
      property parameters : Grip::Parsers::ParameterBox?

      # Deletes request header.
      def delete_req_header(key)
        @request.headers.delete(key)
        self
      end

      # Deletes response header.
      def delete_resp_header(key)
        @response.headers.delete(key)
        self
      end

      # Gets request header.
      def get_req_header(key)
        @request.headers[key]
      end

      # Get cookie from request or nil if key does not exist
      def get_req_cookie(key)
        return @request.cookies[key] if @request.cookies[key]?
        nil
      end

      # Gets response header.
      def get_resp_header(key)
        @response.headers[key]
      end

      # Halts the execution of the endpoint
      def halt
        @response.close
        self
      end

      # Merges the response headers with another hashmap
      def merge_resp_headers(headers)
        @response.headers.merge!(headers)
        self
      end

      # Assigns request header in the headers hashmap.
      def put_req_header(key, value)
        @request.headers[key] = value
        self
      end

      # Assigns response header in the headers hashmap.
      def put_resp_header(key, value)
        @response.headers[key] = value
        self
      end

      # Sets response cookie
      def put_resp_cookie(cookie)
        @response.cookies[cookie.name] = cookie
        self
      end

      # Sets response cookie from string
      def put_resp_cookie(key, val)
        @response.cookies[key] = val
        self
      end

      # Assigns response status code.
      def put_status(status_code = HTTP::Status::OK)
        @response.status_code = status_code.to_i
        self
      end

      # Sends a response with a status code of OK.
      def send_resp(content)
        @response.print(content)
        self
      end

      # Sends a response with the content formated as json.
      def json(content, content_type = "application/json; charset=UTF-8")
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content.to_json)
        self
      end

      # Sends a response with the content formated as html.
      def html(content, content_type = "text/html; charset=UTF-8")
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Sends a response with the content formated as text.
      def text(content, content_type = "text/plain; charset=UTF-8")
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Sends a response with no formating.
      def binary(content, content_type = "application/octet-stream")
        @response.headers.merge!({"Content-Type" => content_type})
        @response.print(content)
        self
      end

      # Fetches the parsed JSON content from an endpoint.
      def fetch_json_params
        @parameters.not_nil!.json
      end

      # Fetches the parsed `GET` query parameters from an endpoint.
      def fetch_query_params
        @parameters.not_nil!.query
      end

      # Fetches the parsed URL encoded parameters from an endpoint.
      def fetch_body_params
        @parameters.not_nil!.body
      end

      # Fetches the parsed multipart data from an endpoint.
      def fetch_file_params
        @parameters.not_nil!.file
      end

      # Fetches the parsed URL data from an endpoint.
      def fetch_path_params
        if @parameters.not_nil!.url.size != 0
          @parameters.not_nil!.url
        else
          @parameters.not_nil!.url
        end
      end

      def redirect(url = "/", status_code = HTTP::Status::FOUND)
        @response.headers["Location"] = url
        @response.status_code = status_code.to_i
        self
      end

      def exec
        with self yield
      end
    end
  end
end
