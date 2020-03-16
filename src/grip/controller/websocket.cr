module Grip
  module Controller
    class WebSocket < Base
      getter? closed = false

      #
      # Initialize the websocket controller with 4096 bytes equivalent buffer size.
      #
      def initialize
        @buffer = Bytes.new(4096)
        @current_message = IO::Memory.new
      end

      #
      # Initialize the websocket controller with a specific buffer size.
      #
      def initialize(buffer_size : Int32)
        @buffer = Bytes.new(buffer_size)
        @current_message = IO::Memory.new
      end

      def on_open(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol)
      end

      def on_ping(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol, on_ping : String)
      end

      def on_pong(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol, on_pong : String)
      end

      def on_message(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol, on_message : String)
      end

      def on_binary(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol, on_binary : Bytes)
      end

      def on_close(context : HTTP::Server::Context, socket : HTTP::WebSocket::Protocol, on_close : String)
      end

      protected def check_open
        raise IO::Error.new "Closed socket" if closed?
      end

      def send(socket, message)
        check_open
        socket.send(message)
      rescue exception
        if !closed?
          @closed = true
          socket.close(exception.message)
        end
        exception
      end

      # It's possible to send a PING frame, which the client must respond to
      # with a PONG, or the server can send an unsolicited PONG frame
      # which the client should not respond to.
      #
      # See `#pong`.
      def ping(socket, message = nil)
        check_open
        socket.ping(message)
      rescue exception
        if !closed?
          @closed = true
          socket.close(exception.message)
        end
        exception
      end

      # Server can send an unsolicited PONG frame which the client should not respond to.
      #
      # See `#ping`.
      def pong(socket, message = nil)
        check_open
        socket.pong(message)
      rescue exception
        if !closed?
          @closed = true
          socket.close(exception.message)
        end
        exception
      end

      def stream(socket, binary = true, frame_size = 1024)
        check_open
        socket.stream(binary: binary, frame_size: frame_size) do |io|
          yield io
        end
      rescue exception
        if !closed?
          @closed = true
          socket.close(exception.message)
        end
        exception
      end

      def close(socket, message = nil)
        return if closed?
        @closed = true
        socket.close(message)
      end

      def run(context, socket)
        #
        # Trigger an on_open function call when a client connects to our endpoint
        #
        on_open(context, socket)

        loop do
          begin
            info = socket.receive(@buffer)
          rescue IO::EOFError
            on_close(context, socket, "")
            break
          end

          case info.opcode
          when HTTP::WebSocket::Protocol::Opcode::PING
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_s
              on_ping(context, socket, message)
              pong(socket, message) unless closed?
              @current_message.clear
            end
          when HTTP::WebSocket::Protocol::Opcode::PONG
            @current_message.write @buffer[0, info.size]
            if info.final
              on_pong(context, socket, @current_message.to_s)
              @current_message.clear
            end
          when HTTP::WebSocket::Protocol::Opcode::TEXT
            @current_message.write @buffer[0, info.size]
            if info.final
              on_message(context, socket, @current_message.to_s)
              @current_message.clear
            end
          when HTTP::WebSocket::Protocol::Opcode::BINARY
            @current_message.write @buffer[0, info.size]
            if info.final
              on_binary(context, socket, @current_message.to_slice)
              @current_message.clear
            end
          when HTTP::WebSocket::Protocol::Opcode::CLOSE
            @current_message.write @buffer[0, info.size]
            if info.final
              message = @current_message.to_s
              on_close(context, socket, message)
              close(socket, message) unless closed?
              @current_message.clear
              break
            end
          end
        end
      end

      def call(context : HTTP::Server::Context)
        if websocket_upgrade_request? context.request
          response = context.response

          version = context.request.headers["Sec-WebSocket-Version"]?
          unless version == HTTP::WebSocket::Protocol::VERSION
            response.status = :upgrade_required
            response.headers["Sec-WebSocket-Version"] = HTTP::WebSocket::Protocol::VERSION
            return
          end

          key = context.request.headers["Sec-WebSocket-Key"]?

          unless key
            response.respond_with_status(:bad_request)
            return
          end

          accept_code = HTTP::WebSocket::Protocol.key_challenge(key)

          response.status = :switching_protocols
          response.headers["Upgrade"] = "websocket"
          response.headers["Connection"] = "Upgrade"
          response.headers["Sec-WebSocket-Accept"] = accept_code
          response.upgrade do |io|
            self.run(context, HTTP::WebSocket::Protocol.new(io))
            io.close
          end
        else
          call_next(context)
        end
      end

      private def websocket_upgrade_request?(request)
        return false unless upgrade = request.headers["Upgrade"]?
        return false unless upgrade.compare("websocket", case_insensitive: true) == 0

        request.headers.includes_word?("Connection", "Upgrade")
      end
    end
  end
end
