module Grip
  module Controllers
    class WebSocket < Grip::Controllers::Base
      getter? closed = false
      property ws : HTTP::WebSocket::Protocol?

      # :nodoc:
      def initialize
        @buffer = Bytes.new(4096)
        @current_message = IO::Memory.new
      end

      def on_open(context, socket)
      end

      def on_ping(context, socket, ping)
      end

      def on_pong(context, socket, pong)
      end

      def on_message(context, socket, message)
      end

      def on_binary(context, socket, binary)
      end

      def on_close(context, socket, close_code, message)
      end

      protected def check_open
        raise IO::Error.new "Closed socket" if closed?
      end

      def send(message)
        check_open
        @ws.not_nil!.send(message)
      end

      # It's possible to send a PING frame, which the client must respond to
      # with a PONG, or the server can send an unsolicited PONG frame
      # which the client should not respond to.
      #
      # See `#pong`.
      def ping(message = nil)
        check_open
        @ws.not_nil!.ping(message)
      end

      # Server can send an unsolicited PONG frame which the client should not respond to.
      #
      # See `#ping`.
      def pong(message = nil)
        check_open
        @ws.not_nil!.pong(message)
      end

      def stream(binary = true, frame_size = 1024)
        check_open
        @ws.not_nil!.stream(binary: binary, frame_size: frame_size) do |io|
          yield io
        end
      end

      @[Deprecated("Use WebSocket#close(code, message) instead")]
      def close(message)
        close(nil, message)
      end

      def close(code : HTTP::WebSocket::CloseCode | Int? = nil, message = nil)
        return if closed?
        @closed = true
        @ws.not_nil!.close(code, message)
      end

      def run(context)
        on_open(context, @ws.not_nil!)

        loop do
          begin
            info = @ws.not_nil!.receive(@buffer)
          rescue
            on_close(context, @ws.not_nil!, HTTP::WebSocket::CloseCode::AbnormalClosure, "")
            @closed = true
            break
          end

          case info.opcode
          when .ping?
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_s
              on_pong(context, @ws.not_nil!, message)
              pong(message) unless closed?
              @current_message.clear
            end
          when .pong?
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_s
              on_pong(context, @ws.not_nil!, message)
              @current_message.clear
            end
          when .text?
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_s
              on_message(context, @ws.not_nil!, message)
              @current_message.clear
            end
          when .binary?
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_slice
              on_binary(context, @ws.not_nil!, message)
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

              on_close(context, @ws.not_nil!, code, message)
              close(code)

              @current_message.clear
              break
            end
          when HTTP::WebSocket::Protocol::Opcode::CONTINUATION
            # TODO: (asterite) I think this is good, but this case wasn't originally handled
          end
        end
      end

      def call(context : HTTP::Server::Context) : HTTP::Server::Context
        if websocket_upgrade_request? context.request
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
            @ws = HTTP::WebSocket::Protocol.new(io, sync_close: true)
            run(context)
            io.close
          end
        else
          raise Exceptions::BadRequest.new
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
