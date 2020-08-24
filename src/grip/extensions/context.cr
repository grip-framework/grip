# `HTTP::Server::Context` is the class which holds `HTTP::Request` and
# `HTTP::Server::Response` alongside with information such as request params,
# request/response content_type, session data and alike.
#
# Instances of this class are passed to an `HTTP::Server` handler.
class HTTP::Server
  class Context
    struct Assigns
      property ip : String?
      property basic : String?
      property jwt : JSON::Any?
    end

    property assigns : Assigns
    property exception : Exception?

    def initialize(@request : Request, @response : Response)
      @assigns = Assigns.new
    end

    def params
      @params ||= Grip::Parsers::ParameterBox.new(@request, route_lookup.params)
    end

    def route
      route_lookup.payload
    end

    def websocket
      ws_route_lookup.payload
    end

    def route_lookup
      Grip::Routers::Http::INSTANCE.lookup_route(@request.method.as(String), @request.path)
    end

    def route_found?
      route_lookup.found?
    end

    def ws_route_lookup
      Grip::Routers::WebSocket::INSTANCE.lookup_ws_route(@request.path)
    end

    def ws_route_found?
      ws_route_lookup.found?
    end

    def delete_req_header(key)
      @request.headers[key].delete
    end

    def delete_resp_header(key)
      @response.headers[key].delete
    end

    def get_req_header(key)
      @request.headers[key]
    end

    def get_resp_header(key)
      @response.headers[key]
    end

    def halt
      @response.close
      self
    end

    def merge_resp_headers(headers)
      @response.headers.merge!(headers)
      self
    end

    def put_req_header(key, value)
      @request.headers[key] = value
      self
    end

    def put_resp_header(key, value)
      @response.headers[key] = value
      self
    end

    def put_status(status_code = HTTP::Status::OK)
      @response.status_code = status_code.to_i
      self
    end

    def send_resp(content, status_code = HTTP::Status::OK)
      @response.status_code = status_code.to_i
      @response.print(content)
    end

    def json(content)
      @response.headers.merge!({"Content-Type" => "application/json"})
      @response.print(content.to_json)
    end

    def html(content)
      @response.headers.merge!({"Content-Type" => "text/html"})
      @response.print(content)
    end

    def text(content)
      @response.headers.merge!({"Content-Type" => "text/plain"})
      @response.print(content)
    end

    # `Grip::DSL::Methods#json?` returns the parsed JSON content from an endpoint.
    def fetch_json_params
      params.json
    end

    # `Grip::DSL::Methods#query?` returns the parsed `GET` query parameters from an endpoint.
    def fetch_query_params
      params.query
    end

    # `Grip::DSL::Methods#body?` returns the parsed URL encoded parameters from an endpoint.
    def fetch_body_params
      params.body
    end

    # `Grip::DSL::Methods#file?` returns the parsed multipart data from an endpoint.
    def fetch_file_params
      params.file
    end

    # `Grip::DSL::Methods#url?` returns the parsed URL data from an endpoint.
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
