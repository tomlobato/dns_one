
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


