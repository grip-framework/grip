module Grip
  module ServerSent
    module Event
      struct Envelope(T)
        include ::JSON::Serializable

        getter type : String
        getter timestamp : Int64
        getter data : T?

        def initialize(
          @type : String,
          @data : T? = nil,
          @timestamp : Int64 = Time.utc.to_unix_ms
        )
        end
      end
    end
  end
end
