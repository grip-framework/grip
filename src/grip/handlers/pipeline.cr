module Grip
  module Handlers
    class Pipeline
      INSTANCE = new
      property pipeline : Hash(Symbol, Array(Grip::Pipes::Base))

      def initialize
        @pipeline = Hash(Symbol, Array(Grip::Pipes::Base)).new
      end

      def add_pipe(valve : Symbol, pipe : Grip::Pipes::Base)
        if @pipeline.has_key?(valve)
          @pipeline[valve].push(pipe)
        else
          @pipeline[valve] = [pipe.as(Grip::Pipes::Base)]
        end
      end
    end
  end
end
