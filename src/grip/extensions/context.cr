module Grip
  module Extensions
    module Context
      # `Assigns` structure contains all of the `Pipe` middleware assignables
      # which are used for context forwarding and information storage.
      struct Assigns
        property ip : String?
        property basic : String?
        property jwt : JSON::Any?
      end

      property assigns = Assigns.new

      # `exception` property is assigned when an endpoint raises an exception while
      # handling the clients request.
      property exception : Exception?

      def initialize(@request : Request, @response : Response); end

      # Creates a getter for the parsed parameters, if not found then parses them.
      def params
        @params ||= Grip::Parsers::ParameterBox.new(@request, route_lookup.params)
      end

      # Gets the payload of the registered route by looking up the radix tree.
      def route
        route_lookup.payload
      end

      # Gets the payload of the registered route by looking up the radix tree.
      def websocket
        ws_route_lookup.payload
      end

      # Looks up the radix tree for the request method and path.
      def route_lookup
        Grip::Routers::Http::INSTANCE.lookup_route(@request.method.as(String), @request.path)
      end

      # Checks if the requested route was found in the radix tree.
      def route_found?
        route_lookup.found?
      end

      # Looks up the radix tree for the request path.
      def ws_route_lookup
        Grip::Routers::WebSocket::INSTANCE.lookup_ws_route(@request.path)
      end

      # Checks if the requested route was found in the radix tree.
      def ws_route_found?
        ws_route_lookup.found?
      end

      # Deletes request header.
      def delete_req_header(key)
        @request.headers[key].delete
        self
      end

      # Deletes response header.
      def delete_resp_header(key)
        @response.headers[key].delete
        self
      end

      # Gets request header.
      def get_req_header(key)
        @request.headers[key]
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
      def json(content)
        @response.headers.merge!({"Content-Type" => "application/json"})
        @response.print(content.to_json)
        self
      end

      # Sends a response with the content formated as html.
      def html(content)
        @response.headers.merge!({"Content-Type" => "text/html"})
        @response.print(content)
        self
      end

      # Sends a response with the content formated as text.
      def text(content)
        @response.headers.merge!({"Content-Type" => "text/plain"})
        @response.print(content)
        self
      end

      # Sends a response with no formating.
      def binary(content)
        @response.print(content)
        self
      end

      # Fetches the parsed JSON content from an endpoint.
      def fetch_json_params
        params.json
      end

      # Fetches the parsed `GET` query parameters from an endpoint.
      def fetch_query_params
        params.query
      end

      # Fetches the parsed URL encoded parameters from an endpoint.
      def fetch_body_params
        params.body
      end

      # Fetches the parsed multipart data from an endpoint.
      def fetch_file_params
        params.file
      end

      # Fetches the parsed URL data from an endpoint.
      def fetch_path_params
        if params.url.size != 0
          params.url
        elsif ws_route_lookup.params.size != 0
          ws_route_lookup.params
        else
          params.url || ws_route_lookup.params
        end
      end
    end
  end
end
