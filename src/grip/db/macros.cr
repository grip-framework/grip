macro storage(path)
    @db = Grip::DB::Connections[{{path}}]
end

macro store(key, value)
    @db.set({{key}}, {{value}}.to_json)
end

macro retrieve(key)
    @db.get({{key}}).to_s
end
