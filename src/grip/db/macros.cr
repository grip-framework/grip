require "json"

module Grip::DB
  macro parent(path)
    Grip::DB::Connections << Grip::DB::Base.new({{path}})
  end

  def storage(path, &block)
    yield Grip::DB::Connections[path]
  end

  macro store(key, value)
    db.set({{key}}, {{value}}.to_json)
  end

  macro retrieve(key)
    db.get({{key}}).to_s
  end
end
