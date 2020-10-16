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
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] added a pipe to a pipeline, valve: #{valve}, pipe: #{pipe}."
        {% end %}

        if @pipeline.has_key?(valve)
          @pipeline[valve].push(pipe)
        else
          @pipeline[valve] = [pipe.as(Pipes::Base)]
        end
      end

      def get(valve : Symbol)
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] requested pipes from a pipeline, valve: #{valve}"
        {% end %}
        @pipeline[valve]
      end

      def get(valves : Array(Symbol))
        if CACHED_PIPES[valves]?
          {% if flag?(:verbose) %}
            puts "#{Time.utc} [info] requested pipes from a pipeline, valve: #{valves}"
          {% end %}
          return CACHED_PIPES[valves]
        end

        pipes = [] of Pipes::Base

        valves.each do |valve|
          @pipeline[valve].each do |_pipe|
            pipes.push(_pipe)
          end
        end

        CACHED_PIPES[valves] = pipes
        {% if flag?(:verbose) %}
          puts "#{Time.utc} [info] requested pipes from a pipeline, valve: #{valves}"
        {% end %}
        pipes
      end

      def call(context : HTTP::Server::Context) : HTTP::Server::Context
      end
    end
  end
end
