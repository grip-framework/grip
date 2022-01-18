module Grip
  struct Log < Log::StaticFormatter
    def run
      string "#{Time.utc} "
      severity
      string " "
      message
    end
  end
end

Log.setup(:info, Log::IOBackend.new(formatter: Grip::Log))
