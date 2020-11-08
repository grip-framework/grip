require "./*"

class HTTP::Server::Context
  include Grip::Extensions::Context
end

class HTTP::Server::Response
  include Grip::Extensions::Response
end

struct NamedTuple
  include Grip::Extensions::NamedTuple
end
