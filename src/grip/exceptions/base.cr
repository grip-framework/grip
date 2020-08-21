module Grip
  module Exceptions
    abstract class Base < Exception
      getter status : HTTP::Status?

      abstract def status_code : Int32
    end
  end
end
