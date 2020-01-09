module Grip::DB
  class Connections
    class_getter registered_connections = [] of Grip::DB::Base

    # Registers the given *adapter*.  Raises if an adapter with the same name has already been registered.
    def self.<<(database : Grip::DB::Base) : Nil
      raise "Database with path '#{database.path}' has already been registered." if @@registered_connections.any? { |conn| conn.path == database.path }
      @@registered_connections << database
    end

    def self.[](path : String) : Grip::DB::Base

      database = registered_connections.find { |conn| conn.path == path }
      if !database.is_a?(Nil)
        database
      else
        puts "\e[1;33mWARNING: Created or re-connected a new database for a non-existing connection at '#{path}'.\e[0m\nYou can pre-define a connection via 'Grip::DB::Connections << Grip::DB::Base.new(:#{path})',\nIt doesn't make a big difference it just saves the connection into a global scope,\nSo the framework will have some knowledge about your database which was predefined and not misspelled."
        placeholder = Grip::DB::Base.new(path)
        @@registered_connections << placeholder
        placeholder
      end
    end
  end
end
