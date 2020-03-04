module Grip
  module Core
    class Pipeline
      INSTANCE = new
      property pipeline : Hash(Symbol, Array(Grip::Pipe::Base))

      def initialize
        @pipeline = Hash(Symbol, Array(Grip::Pipe::Base)).new
      end

      def add_pipe(valve : Symbol, pipe : Grip::Pipe::Base)
        if @pipeline.has_key?(valve)
          @pipeline[valve].push(pipe)
        else
          @pipeline[valve] = [pipe.as(Grip::Pipe::Base)]
        end
      end
    end
  end
end
