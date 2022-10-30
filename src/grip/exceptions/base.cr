module Grip
  module Exceptions
    abstract class Base < Exception
      getter status_code : HTTP::Status = HTTP::Status::IM_A_TEAPOT
    end
  end
end
