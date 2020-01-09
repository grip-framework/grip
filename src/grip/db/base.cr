require "leveldb"

module Grip::DB
  class Base
    getter path : String

    def initialize(@path : String)
      @db = LevelDB::DB.new(@path)
    end

    def database : LevelDB::DB
      @_database ||= @db
    end

    def open(&block)
      yield database
    end

    def get(key : String)
      open do |db|
        while !db.opened?
          db.open
          if db.opened?
            break
          end
        end
        db.get(key)
      end
    end

    def set(key : String, value : String)
      open do |db|
        while !db.opened?
          db.open
          if db.opened?
            break
          end
        end
        db.put(key, value)
      end
    end
  end
end
