require "leveldb"

module Grip::DB
  class Base
    getter path : Symbol

    def initialize(@path : Symbol); end

    def database : LevelDB::DB
      @_database ||= LevelDB::DB.new(@path.to_s)
    end

    def open(&block)
      yield database
    end

    def get(key : String)
      open do |db|
        db.get(key)
      end
    end

    def set(key : String, value : String)
      open do |db|
        db.put(key, value)
      end
    end
  end
end
