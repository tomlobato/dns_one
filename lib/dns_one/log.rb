
class Log < Logger
    class << self

        Logger::Severity::constants.each_with_index do |severity, severity_num|
            next if severity == :UNKNOWN
            method_name = severity.to_s[0].downcase
            define_method(method_name) do |msg|
                log severity_num, msg
            end
        end

        def setup file, syslog_name
            @syslog = Syslog::Logger.new syslog_name
            @log_file = setfile file
            @logger = Logger.new @log_file
        end

        def setfile file
            if File.exists? file and File.writable? file
                file
            elsif File.writable? File.dirname(file)
                file
            else
                STDOUT
            end
        end

        def log severity, msg
            met_name = Logger::Severity::constants[severity].downcase
            @logger.send met_name, msg
            if severity >= Logger::WARN
                @syslog.send met_name, msg
            end
            if severity == Logger::FATAL and 
               @log_file != STDOUT and 
               @log_file != STDERR
                STDERR.puts msg
            end
        end

        def exc e
            e e.desc
        end

        def logger
            @logger
        end
    end
end

