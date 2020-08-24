require "./*"

# We are patching the String class and Number struct to extend the predicates
# available. This will allow to add friendlier methods for validation cases.
class String
  include Grip::Extensions::String
end

abstract struct Number
  include Grip::Extensions::Number
end

class HTTP::Server::Context
  include Grip::Extensions::HTTPServerContext
end

class HTTP::Server::Response
  include Grip::Extensions::HTTPServerResponse
end
