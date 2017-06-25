
class String
    def to_a
        [self]
    end
    def strip_text
        split("\n")
        .map{|l| l.strip}
        .join("\n")
    end
end

class Exception
    def desc
        "#{e.class}: #{ message }\n#{ backtrace&.join "\n" }"
    end
    def puts_stderr
        STDERR.puts e.desc
    end
end

def match_root stat
    stat.uid == 0 && stat.gid == 0
end
