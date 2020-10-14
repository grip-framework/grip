module Grip
  module Handlers
    # :nodoc:
    class Pipeline
      property pipeline : Hash(Symbol, Array(Pipes::Base))

      CACHED_PIPES = {} of Array(Symbol) => Array(Pipes::Base)

      def initialize
        @pipeline = Hash(Symbol, Array(Pipes::Base)).new
      end

      def add_pipe(valve : Symbol, pipe : Pipes::Base)
        if @pipeline.has_key?(valve)
          @pipeline[valve].push(pipe)
        else
          @pipeline[valve] = [pipe.as(Pipes::Base)]
        end
      end

      def get(valve : Symbol)
        @pipeline[valve]
      end

      def get(valves : Array(Symbol))
        return CACHED_PIPES[valves] if CACHED_PIPES[valves]?

        pipes = [] of Pipes::Base

        valves.each do |valve|
          @pipeline[valve].each do |_pipe|
            pipes.push(_pipe)
          end
        end

        CACHED_PIPES[valves] = pipes
        pipes
      end

      def call(context : HTTP::Server::Context) : HTTP::Server::Context
      end
    end
  end
end
