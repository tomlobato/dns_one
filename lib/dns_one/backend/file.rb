
module DnsOne; module Backend; class File

    def initialize file
        @domain_map = {}
        load file
    end

    def find dom_name
        @domain_map[dom_name.downcase]
    end

    def allow_cache
        false
    end

    private

    def load file
        ::File.open(file).each_line do |line|
            line.strip!
            domain_name, rec_set_name = line
                .split(/[,\s]+/)
            if domain_name and not domain_name.empty?
                @domain_map[domain_name.strip.downcase] = rec_set_name&.strip || ''
            else
                Log.w "Ignoring #{file} line: #{line}"
            end
        end
    end

end; end; end