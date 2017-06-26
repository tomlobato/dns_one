
class Log < Logger
    class << self

        # 'def [d|i|w|e|f] msg' for DEBUG INFO WARN ERROR FATAL
        Logger::Severity::constants.each_with_index do |severity, severity_num|
            next if severity == :UNKNOWN
            method_name = severity.to_s[0].downcase
            define_method(method_name) do |msg|
                log severity_num, msg
            end
        end

        def setup file, syslog_name, syslog_min_severity = Logger::WARN
            @syslog_min_severity = syslog_min_severity
            @syslog = Syslog::Logger.new syslog_name
            @log_file = setfile file
            @logger = Logger.new @log_file
        end

        def change_log_file file
            new_log_file = setfile file, allow_stdout: false
            if new_log_file and new_log_file != @log_file
                @log_file = new_log_file
                @logger = Logger.new @log_file
            end
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

        def setfile file, allow_stdout: true
            if [STDOUT, STDERR].include? file or
               File.writable? file or
               File.writable? File.dirname(file)
                file
            elsif allow_stdout
                STDOUT
            end
        end

        def log severity, msg
            met_name = Logger::Severity::constants[severity].downcase

            @logger.send met_name, msg

            if severity >= @syslog_min_severity
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

