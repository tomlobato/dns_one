
class Log < Logger
    SYSLOG_MIN_SEVERITY = Logger::WARN

    class << self

        # 'def [d|i|w|e|f] msg' for DEBUG INFO WARN ERROR FATAL
        Logger::Severity::constants.each_with_index do |severity, severity_num|
            next if severity == :UNKNOWN
            method_name = severity.to_s[0].downcase
            define_method(method_name) do |msg|
                log severity_num, msg
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

        def exc e
            e e.desc
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
            met_name = Logger::Severity::constants[severity].downcase

            @logger.send met_name, msg

            if severity >= SYSLOG_MIN_SEVERITY
                @syslog.send met_name, msg
            end

            if severity == Logger::FATAL and 
               @log_file != STDOUT and 
               @log_file != STDERR
                STDERR.puts msg
            end
        end
    end
end

