module Grip
  module ServerSent
    class Stream
      getter context : HTTP::Server::Context
      getter capacity : Int32
      getter strategy : Strategy

      # The internal bounded queue enforcing backpressure
      private getter queue : Channel(String)
      private getter? closed : Bool = false

      def initialize(
        @context : HTTP::Server::Context,
        @capacity : Int32 = 100,
        @strategy : Strategy = Strategy::DropOldest
      )
        setup_headers
        @queue = Channel(String).new(@capacity)
        start_worker
      end

      def emit(
        type : Event::Type,
        data : T = nil,
        *,
        id : String | Int? = nil,
        retry : Time::Span? = nil
      ) : self forall T
        event_type = type.to_s

        envelope = Event::Envelope(T).new(
          type: event_type,
          data: data,
        )

        send(
          data: envelope.to_json,
          event: event_type,
          id: id,
          retry: retry,
        )
      end

      # Protocol-level Heartbeat
      @[AlwaysInline]
      def ping : self
        emit(Event::Type::Ping)
      end

      # Protocol-level Connection Acknowledgment
      @[AlwaysInline]
      def connected(connection_id : String) : self
        emit(Event::Type::Connected, data: {connection_id: connection_id})
      end

      # Protocol-level Error Emitting
      @[AlwaysInline]
      def error(data : T = nil) : self forall T
        emit(Event::Type::Error, data: data)
      end

      # Formats and enqueues the payload without blocking the caller fiber (unless using strategy: Block).
      def send(
        data : String,
        *,
        event : String? = nil,
        id : String | Int? = nil,
        retry : Time::Span? = nil
      ) : self
        return self if @closed

        raw_payload = String.build do |io|
          io.puts("event: #{event}") if event
          io.puts("id: #{id}") if id
          io.puts("retry: #{retry.total_milliseconds.to_i}") if retry

          data.each_line(chomp: true) do |line|
            io.puts("data: #{line}")
          end

          io.puts # Trailing newline required by SSE spec
        end

        enqueue(raw_payload)
        self
      end

      # Keeps the SSE handler fiber alive by sending periodic heartbeats.
      def await(interval : Time::Span = 15.seconds) : Nil
        loop do
          break if closed?

          sleep interval

          break if closed?

          ping
        rescue ::IO::Error | ::HTTP::Server::ClientError
          # Client disconnected or TCP pipe broke
          close
          break
        end
      end

      def comment(text : String) : self
        return self if @closed
        enqueue(": #{text}\n\n")
        self
      end

      @[AlwaysInline]
      def close : Nil
        return if @closed
        @closed = true
        @queue.close
      end

      # Handles non-blocking and blocking buffer pushes based on the selected backpressure strategy
      private def enqueue(payload : String) : Nil
        case @strategy
        when .block?
          # Standard blocking channel send. Pauses producer fiber if full.
          @queue.send(payload) unless @closed
        when .drop_oldest?
          select
          when @queue.send(payload)
            # Fits in queue
          else
            # Buffer full! Evict oldest frame to make room for live real-time payload
            @queue.receive?
            @queue.send(payload) rescue nil
          end
        when .drop_newest?
          select
          when @queue.send(payload)
            # Fits in queue
          else
            # Buffer full! Discard incoming payload to prevent RAM bloat
          end
        end
      end

      # Worker fiber that pops messages from the queue and flushes down the socket sequentially
      private def start_worker : Nil
        spawn(name: "grip.server-sent.event.stream") do
          loop do
            payload = @queue.receive?
            break unless payload # Channel closed via #close

            @context.response.print(payload)
            @context.response.flush
          end
        rescue ::IO::Error | ::HTTP::Server::ClientError
          # Client closed the tab, aborted curl, or network dropped
          close
        ensure
          close
        end
      end

      @[AlwaysInline]
      private def setup_headers : Nil
        @context.response.content_type = "text/event-stream; charset=utf-8"
        @context.response.headers["Cache-Control"] = "no-cache"
        @context.response.headers["X-Accel-Buffering"] = "no"

        unless @context.response.headers.has_key?("Connection")
          @context.response.headers["Connection"] = "keep-alive"
        end
      end
    end
  end
end
