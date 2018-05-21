module DnsOne; module Backend; class DB

    DB_FNAME = "stat.db"
    META_STAT_ON = false
    META_STAT_FILE = '/tmp/dnsone_sql_prof.log'

    def initialize conf = {}
        @conf = conf
	    
        # Setup logger and current working dir
        DnsOne.new if @conf[:from_outside]
        
        ensure_db
    end

    def on_response ip_address, domain_name, res_class, rcode, resp_log, from_cache
    	Global.logger.debug "saving stat (user: #{ `id -un #{Process.uid}`.strip })"
        rsql(
            "INSERT INTO responses (time, rcode, req_resource, cache) VALUES (?, ?, ?, ?)", 
            [
                Time.now.to_i, 
                Resolv::DNS::RCode.const_get(rcode), 
                res_class::TypeValue, 
                (from_cache ? 1 : 0)
            ]
        )
    rescue => e
        Global.logger.error e.desc
    end

    # select rcode, count(*) from responses where time > strftime('%s', 'now') - 300 group by rcode
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

        rsql(s).each do |row|
            _counter, count = row
            counts[_counter] = count
        end

        counts
    end

    def self.print
        stat = new(from_outside: true, readonly: true)
        %w(rcode req_resource cache).each do |key|
            puts "--- #{key} ---"
            stat.get_counts(key.to_sym).each_pair do |k, v|
                _k = case key
                when 'rcode'
                    stat.rcodes[k]
                when 'req_resource'
                    stat.request_resources[k]
                when 'cache'
                    k == 0 ? :miss : :hit
                end
                puts "#{_k || k}\t#{v}"
            end
        end
    end

    def rcodes
        unless defined? @@rcodes
            @@rcodes = Hash[ 
                Resolv::DNS::RCode.constants.map{|c| 
                    [
                        Resolv::DNS::RCode.const_get(c), 
                        Util.const_underscore(c)
                    ] 
                } 
            ]
        end
        @@rcodes
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

        opts = {}
        opts[:readonly] = true if @conf[:readonly]

	    # Global.logger.info "Opening stat db #{db_file} (cwd: #{Dir.pwd})."
        @db = SQLite3::Database.new db_file, opts

        if new_db
            File.chmod 0644, db_file
    	    File.chown `id -u #{@conf[:user]}`.to_i, nil, db_file if @conf[:user]
            create_tables 
        end
    end
    
    def create_tables
        @db.execute_batch <<-SQL
            create table responses (
                time int,
                rcode int,
                req_resource int,
                cache int
            );
            CREATE INDEX responses_time_rcode ON responses (time, rcode);
            CREATE INDEX responses_time_req_resource ON responses (time, req_resource);
            CREATE INDEX responses_time_cache ON responses (time, cache);
        SQL
    end


    def db_file
        DB_FNAME
    end

    def rsql *sql
        t0 = Time.now if META_STAT_ON
        res = @db.execute *sql
        meta_stats t0, sql if META_STAT_ON
        res
    end

    def meta_stats t0, sql
        time = Time.now.strftime '%y%m%d-%H%M%S.%L'
        dur = "%.3f" % ((Time.now - t0) * 1000.0)
        sql = [sql].flatten[0].gsub /\s+/, ' '

        @meta_stats_log ||= Logger.new META_STAT_FILE
        @meta_stats_log.info "#{time} #{dur} #{sql}"
    end

end; end; end

