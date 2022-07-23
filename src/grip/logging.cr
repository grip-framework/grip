module Grip::Logging
  struct Formatter < Log::StaticFormatter
    def run
      string "#{Time.utc} "
      severity
      string " "
      message
    end
  end

  Log.setup(:info, Log::IOBackend.new(formatter: Grip::Logging::Formatter))
end
