module Grip
    class LogService
        include SimpleRpc::Proto

        def info(msg : String) : Int32
            begin
               Grip.config.logger.write "[\u001b[34minfo\u001b[0m] #{msg}\n" 
               0
            rescue _exception
               1
            end
        end

        def debug(msg : String) : Int32
            begin
               Grip.config.logger.write "[\u001b[35mdebug\u001b[0m] #{msg}\n" 
               0
            rescue _exception
               1
            end
        end

        def message(msg : String) : Int32
            begin
               Grip.config.logger.write "[\u001b[36mmessage\u001b[0m] #{msg}\n" 
               0
            rescue _exception
               1
            end
        end

        def warning(msg : String) : Int32
            begin
               Grip.config.logger.write "[\u001b[33mwarning\u001b[0m] #{msg}\n" 
               0
            rescue _exception
               1
            end
        end

        def error(msg : String) : Int32
            begin
               Grip.config.logger.write "[\u001b[31merror\u001b[0m] #{msg}\n" 
               0
            rescue _exception
               1
            end
        end
    end
end