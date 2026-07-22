module Grip
  module ServerSent
    enum Strategy
      # Drops the oldest un-flushed frame to make room for live real-time data (Default)
      DropOldest

      # Ignores incoming frames while the buffer is full until network capacity frees up
      DropNewest

      # Blocks the calling fiber until room opens in the queue (Preserves strict ordering & delivery)
      Block
    end
  end
end
