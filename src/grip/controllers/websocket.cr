module Grip
  module Controllers
    class WebSocket < Base
      include Helpers::Singleton
      alias Socket = HTTP::WebSocket::Protocol

      getter? closed = false

      # :nodoc:
      def initialize
        @buffer = Bytes.new(4096)
        @current_message = IO::Memory.new
      end

      def on_open(context : Context, socket : Socket) : Void
      end

      def on_ping(context : Context, socket : Socket, message : String) : Void
      end

      def on_pong(context : Context, socket : Socket, message : String) : Void
      end

      def on_message(context : Context, socket : Socket, message : String) : Void
      end

      def on_binary(context : Context, socket : Socket, binary : Bytes) : Void
      end

      def on_close(context : Context, socket : Socket, close_code : HTTP::WebSocket::CloseCode | Int?, message : String) : Void
      end

      protected def check_open
        raise IO::Error.new "Closed socket" if closed?
      end

      def run(context, socket)
        on_open(context, socket)

        loop do
          begin
            info = socket.receive(@buffer)
          rescue
            on_close(context, socket, HTTP::WebSocket::CloseCode::AbnormalClosure, "")
            @closed = true
            break
          end

          case info.opcode
          when .ping?
            @current_message.write @buffer[0, info.size]
            if info.final
              on_ping(context, socket, @current_message.to_s)
              @current_message.clear
            end
          when .pong?
            @current_message.write @buffer[0, info.size]
            if info.final
              on_pong(context, socket, @current_message.to_s)
              @current_message.clear
            end
          when .text?
            @current_message.write @buffer[0, info.size]
            if info.final
              on_message(context, socket, @current_message.to_s)
              @current_message.clear
            end
          when .binary?
            @current_message.write @buffer[0, info.size]
            if info.final
              on_binary(context, socket, @current_message.to_slice)
              @current_message.clear
            end
          when .close?
            @current_message.write @buffer[0, info.size]
            if info.final
              @current_message.rewind
              if @current_message.size >= 2
                code = @current_message.read_bytes(UInt16, IO::ByteFormat::NetworkEndian).to_i
                code = HTTP::WebSocket::CloseCode.new(code)
              else
                code = HTTP::WebSocket::CloseCode::NoStatusReceived
              end
              message = @current_message.gets_to_end

              on_close(context, socket, code, message)
              socket.close(code, message)

              @current_message.clear
              break
            end
          when HTTP::WebSocket::Protocol::Opcode::CONTINUATION
            # TODO: (asterite) I think this is good, but this case wasn't originally handled
          end
        end
      end

      def call(context : Context) : Context
        unless websocket_upgrade_request? context.request
          raise Exceptions::BadRequest.new
        end

        response = context.response

        version = context.request.headers["Sec-WebSocket-Version"]?
        unless version == HTTP::WebSocket::Protocol::VERSION
          response.status = :upgrade_required
          response.headers["Sec-WebSocket-Version"] = HTTP::WebSocket::Protocol::VERSION
          return context
        end

        key = context.request.headers["Sec-WebSocket-Key"]?

        unless key
          response.respond_with_status(:bad_request)
          return context
        end

        accept_code = HTTP::WebSocket::Protocol.key_challenge(key)

        response.status = :switching_protocols
        response.headers["Upgrade"] = "websocket"
        response.headers["Connection"] = "Upgrade"
        response.headers["Sec-WebSocket-Accept"] = accept_code
        response.upgrade do |io|
          socket = HTTP::WebSocket::Protocol.new(io, sync_close: true)
          run(context, socket)
        end

        context
      end

      private def websocket_upgrade_request?(request)
        return false unless upgrade = request.headers["Upgrade"]?
        return false unless upgrade.compare("websocket", case_insensitive: true) == 0

        request.headers.includes_word?("Connection", "Upgrade")
      end
    end
  end
end
