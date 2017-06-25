
module Backend; class File
    def initialize file
        @domain_map = {}
        load_file file
    end

    def find dom_name
        @domain_map[dom_name.downcase]
    end

    private

    def load
        File.open(file).each_line do |line|
            domain_name, rec_set_name = line
                .strip
                .split(/[,\s]+/)
            @domain_map[domain_name.strip.downcase] = rec_set_name&.strip || ''
        end
    end
end; end