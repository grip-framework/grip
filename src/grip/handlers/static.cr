{% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
  require "compress/gzip"
  require "compress/deflate"
{% else %}
  require "zlib"
{% end %}

module Grip
  module Handlers
    class Static < HTTP::StaticFileHandler
      def initialize(public_dir : String, @fallthrough = false, @directory_listing = false, @routing = "/")
        @public_dir = Path.new(public_dir).expand
      end

      def call(context : HTTP::Server::Context)
        return allow_get_or_head(context) unless method_get_or_head?(context.request.method)

        original_path = context.request.path.not_nil!
        request_path = URI.decode(original_path)

        # File path cannot contain '\0' (NUL) because all filesystem I know
        # don't accept '\0' character as file name.
        if request_path.includes? '\0'
          context.response.status_code = 400
          return
        end

        is_dir_path = dir_path? original_path
        expanded_path = Path.posix(request_path).expand("/").to_s
        expanded_path += "/" if is_dir_path && !dir_path?(expanded_path)
        relative_path = request_path.lchop?(routing) || begin
          call_next(context)
          expanded_path
        end

        is_dir_path = dir_path? expanded_path
        file_path = File.join(@public_dir, Path[relative_path])
        root_file = File.join(@public_dir, Path[relative_path], "index.html")

        if is_dir_path && File.exists? root_file
          return if etag(context, root_file)
          return context.send_file(root_file, gzip_enabled: self.class.config_gzip?(static_config))
        end

        is_dir_path = Dir.exists?(file_path) && !is_dir_path
        if request_path != expanded_path || is_dir_path
          redirect_to context, file_redirect_path(expanded_path, is_dir_path)
        end

        call_next_with_file_path(context, request_path, file_path)
      end

      private def dir_path?(path)
        path.ends_with? "/"
      end

      private def method_get_or_head?(method)
        method == "GET" || method == "HEAD"
      end

      private def allow_get_or_head(context)
        if @fallthrough
          call_next(context)
        else
          context.response.status_code = 405
          context.response.headers.add("Allow", "GET, HEAD")
        end

        nil
      end

      private def file_redirect_path(path, is_dir_path)
        "#{path}/#{is_dir_path ? "" : "/"}"
      end

      private def call_next_with_file_path(context, request_path, file_path)
        config = static_config

        if Dir.exists?(file_path)
          if config.is_a?(Hash) && config["dir_listing"] == true
            context.response.content_type = "text/html;charset=UTF-8;"
            directory_listing(context.response, request_path, file_path)
          else
            call_next(context)
          end
        elsif File.exists?(file_path)
          return if etag(context, file_path)
          context.send_file(file_path, gzip_enabled: self.class.config_gzip?(static_config))
        else
          call_next(context)
        end
      end

      private def static_config
        {"dir_listing" => @directory_listing, "gzip" => true}
      end

      private def etag(context, file_path)
        etag = %{W/"#{File.info(file_path).modification_time.to_unix}"}
        context.response.headers["ETag"] = etag
        return false if !context.request.headers["If-None-Match"]? || context.request.headers["If-None-Match"] != etag
        context.response.headers.delete "Content-Type"
        context.response.content_length = 0
        context.response.status_code = 304 # not modified
        true
      end

      def self.config_gzip?(config)
        config.is_a?(Hash) && config["gzip"] == true
      end

      getter routing : String
    end
  end
end
