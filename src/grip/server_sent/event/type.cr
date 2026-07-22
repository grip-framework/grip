module Grip
  module ServerSent
    module Event
      enum Type
        Ping
        Connected
        Data
        Information
        Warning
        Error
        Close
      end
    end
  end
end
