module Grip
  module Helpers
    class FileDownload
      def self.send_file(context, path : String, mime_type : String? = nil, gzip_enabled : Bool = false)
        file_path = File.expand_path(path, Dir.current)
        mime_type ||= mime_type(file_path)
        context.response.content_type = mime_type

        add_response_headers(context)

        minsize = 860 # http://webmasters.stackexchange.com/questions/31750/what-is-recommended-minimum-object-size-for-gzip-performance-benefits ??
        request_headers = context.request.headers
        filesize = File.size(file_path)

        File.open(file_path) do |file|
          next multipart(file, context) if next_multipart?(context)

          if request_headers.includes_word?("Accept-Encoding", "gzip") && gzip_enabled && filesize > minsize && Support::MimeTypes.zip_types(file_path)
            gzip_encoding(context, file)
          elsif request_headers.includes_word?("Accept-Encoding", "deflate") && gzip_enabled && filesize > minsize && Support::MimeTypes.zip_types(file_path)
            deflate_endcoding(context, file)
          else
            context.response.content_length = filesize
            IO.copy(file, context.response)
          end
        end
        return
      end

      private def self.add_response_headers(context : HTTP::Server::Context)
        context.response.headers.merge!({
          "Accept-Ranges"          => "bytes",
          "X-Content-Type-Options" => "nosniff",
          "Cache-Control"          => "private, max-age=3600",
        })
      end

      private def self.next_multipart?(context)
        context.request.method == "GET" && context.request.headers.has_key?("Range")
      end

      private def self.gzip_encoding(context, file)
        context.response.headers["Content-Encoding"] = "gzip"
        {% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
          Compress::Gzip::Writer.open(context.response) do |deflate|
            IO.copy(file, deflate)
          end
        {% else %}
          Gzip::Writer.open(context.response) do |deflate|
            IO.copy(file, deflate)
          end
        {% end %}
      end

      private def self.deflate_endcoding(context, file)
        context.response.headers["Content-Encoding"] = "deflate"
        {% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
          Compress::Deflate::Writer.open(context.response) do |deflate|
            IO.copy(file, deflate)
          end
        {% else %}
          Flate::Writer.open(context.response) do |deflate|
            IO.copy(file, deflate)
          end
        {% end %}
      end

      private def self.multipart(file, context)
        # See http://httpwg.org/specs/rfc7233.html
        fileb = file.size

        range = context.request.headers["Range"]
        match = range.match(/bytes=(\d{1,})-(\d{0,})/)

        startb = 0
        endb = 0

        if match
          if match.size >= 2
            startb = match[1].to_i { 0 }
          end

          if match.size >= 3
            endb = match[2].to_i { 0 }
          end
        end

        if endb == 0
          endb = fileb - 1
        end

        if startb < endb && endb < fileb
          content_length = 1 + endb - startb
          context.response.status_code = 206
          context.response.content_length = content_length
          context.response.headers["Accept-Ranges"] = "bytes"
          context.response.headers["Content-Range"] = "bytes #{startb}-#{endb}/#{fileb}" # MUST

          if startb > 1024
            skipped = 0
            # file.skip only accepts values less or equal to 1024 (buffer size, undocumented)
            until skipped + 1024 > startb
              file.skip(1024)
              skipped += 1024
            end
            if skipped - startb > 0
              file.skip(skipped - startb)
            end
          else
            file.skip(startb)
          end

          IO.copy(file, context.response, content_length)
        else
          context.response.content_length = fileb
          context.response.status_code = 200 # Range not satisfiable, see 4.4 Note
          IO.copy(file, context.response)
        end
      end

      private def self.mime_type(path)
        Support::MimeTypes.mime_type File.extname(path)
      end
    end
  end
end
