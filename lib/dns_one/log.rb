
class Log < Logger
    SYSLOG_MIN_SEVERITY = Logger::WARN

    class << self

        # 'def [d|i|w|e|f] msg' for DEBUG INFO WARN ERROR FATAL
        Logger::Severity::constants.each do |severity|
            method_name = severity.to_s[0].downcase
            define_method(method_name) do |msg|
                log severity, msg
            end
        end

        def setup
            @syslog = Syslog::Logger.new "dns_one"
            @log_file = setfile "/var/log/dns_one.log"
            @logger = Logger.new @log_file
            @logger.level = Logger::INFO
        end

        def ruby_dns_logger
            l = Logger.new setfile("/var/log/dns_one_rubydns.log")
            l.level = Logger::WARN
            l
        end

        def exc exception
            e exception.desc
        end

        def logger
            @logger
        end

        def log_file_desc
            case @log_file
            when STDOUT
                'STDOUT'
            when STDERR
                'STDERR'
            else
                @log_file
            end
        end

        private

        def setfile file
            if File.writable?(file) or File.writable?(File.dirname(file))
                file
            else
                STDERR
            end
        end

        def log severity, msg
            met_name = severity.downcase

            @logger.send met_name, msg

            if sev_num(severity) >= SYSLOG_MIN_SEVERITY
                @syslog.send met_name, msg
            end
        end

        def sev_num sev
            Object.const_get "Logger::#{sev}"
        end
    end
end

