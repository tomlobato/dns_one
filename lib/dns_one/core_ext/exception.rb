
class Exception
    def desc
        "#{e.class}: #{ message }\n#{ backtrace&.join "\n" }"
    end
    def puts_stderr
        STDERR.puts e.desc
    end
end
