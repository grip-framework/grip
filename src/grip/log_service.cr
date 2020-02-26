module Grip
    class LogService
        include SimpleRpc::Proto

        def info(msg : String) : Void
            Grip.config.logger.write "[\u001b[34minfo\u001b[0m] #{msg}\n"
        end

        def debug(msg : String) : Void
            Grip.config.logger.write "[\u001b[35mdebug\u001b[0m] #{msg}\n"
        end

        def message(msg : String) : Void
            Grip.config.logger.write "[\u001b[36mmessage\u001b[0m] #{msg}\n"
        end

        def warning(msg : String) : Void
            Grip.config.logger.write "[\u001b[33mwarning\u001b[0m] #{msg}\n"
        end

        def error(msg : String) : Void
            Grip.config.logger.write "[\u001b[31merror\u001b[0m] #{msg}\n"
        end
    end
end