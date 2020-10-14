require "./*"

class HTTP::Server::Context
  include Grip::Extensions::Context
end

class HTTP::Server::Response
  include Grip::Extensions::Response
end
