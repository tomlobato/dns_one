module DnsOne; class Stat

    def initialize conf = {}
        @conf = conf
        ensure_db
    end

    def save rcode, req_resource, cache
        @db.execute(
            "INSERT INTO responses (time, rcode, req_resource, cache) VALUES (?, ?, ?, ?)", 
            [
                Time.now.to_i, 
                Resolv::DNS::RCode.const_get(rcode), 
                req_resource::TypeValue, 
                (cache ? 1 : 0)
            ]
        )
    rescue => e
        Log.e e
    end

    def get_counts counter, from = nil
        validate_counter counter
        validate_from from

        from ||= (Time.now - 5 * 60).to_i

        s = <<-SQL
            select #{counter}, count(*) 
            from responses 
            where time > #{from}
            group by #{counter}
        SQL

        counts = {}

        @db.execute(s) do |row|
            _counter, count = row
            counts[_counter] = count
        end

        counts
    end

    private

    def validate_counter counter
        unless [:rcode, :req_resource, :cache].include? counter
            raise "invalid arg #{counter}"
        end
    end

    def validate_from from
        case from
        when nil, Integer
        when String
            unless from =~ /^\d+$/
                raise "invalid arg #{from}"
            end
        else
            raise  "invalid arg class #{from.class}"
        end
    end

    def ensure_db
        new_db = !File.exists?(db_file)
        @db = SQLite3::Database.new db_file
        create_tables if new_db
    end
    
    def create_tables
        sqls = []

        sqls << <<-SQL
            create table responses (
                time int,
                rcode int,
                req_resource int,
                cache int
            );
        SQL
        
        sqls <<  <<-SQL
            CREATE INDEX responses_time         ON responses (time);
        SQL

        sqls <<  <<-SQL
            CREATE INDEX responses_rcode        ON responses (rcode);
        SQL

        sqls <<  <<-SQL
            CREATE INDEX responses_req_resource ON responses (req_resource);
        SQL

        sqls <<  <<-SQL
            CREATE INDEX responses_cache        ON responses (cache);
        SQL

        sqls.each{|sql| @db.execute sql }
    end


    def db_file
        @conf[:db_file]
    end

    def request_resources
        unless defined? @@request_resources
            @@request_resources = {}
            %w(A AAAA ANY CNAME HINFO MINFO MX NS PTR SOA TXT WKS).each do |res|
                val = Object.const_get("Resolv::DNS::Resource::IN::#{res}")::TypeValue
                @@request_resources[val] = res.downcase
            end
        end
        @@request_resources
    end

    def const_underscore name
        name = name.to_s.dup
        name.gsub!('::', '/')
        name.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        name.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        name.tr!("-", "_")
        name.downcase!
        name
    end

    def rcodes
        unless @@rcodes
            @@rcodes = Hash[ 
                Resolv::DNS::RCode.constants.map{|c| 
                    [
                        Resolv::DNS::RCode.const_get(c), 
                        const_underscore(c)
                    ] 
                } 
            ]
        end
        @@rcodes
    end
end; end

