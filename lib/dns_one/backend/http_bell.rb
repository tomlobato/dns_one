
# HTTPBell
# At initialization:
# 1) Fetches all domains from @conf[:http_bell_url] and keeps in memory
# 2) Open TCP port @conf[:http_bell_port] and fetches new domains incrementally upon connect(2)

module DnsOne; module Backend; class HTTPBell < Base

    def initialize conf
        @conf = conf
        @domains = {}
        @last_id = nil
        update
        listen_updater_bell
    end

    def find dom_name
        @domains[dom_name]
    end

    def allow_cache
        false
    end

    private

    def update
        log_update :start

        recs = fetch

        recs.each do |rec|
            id, domain = rec
            @domains[domain] = @conf[:http_bell_record_set]
            if !@last_id || @last_id < id
                @last_id = id
            end
        end

        log_update :end, recs
    end

    def fetch
        last_id = @last_id || 0

        url = @conf[:http_bell_url].sub '$id', last_id.to_s

        recs = `curl #{url}`
            .split(/\n+/)
            .map{ |r| 
                id, domain = r.strip.split /\s+/
                if id !~ /^\d+$/ || domain !~ Util::DOM_REGEX
                    Log.w "invalid line '#{r}'"
                    nil
                else
                    [id.to_i, domain.downcase]
                end
            }.compact

        recs
    end

    def log_update point, recs = nil
        case point
        when :start
            @log_update_t0 = Time.now
            Log.i "update`ing..."
            system "echo 'update`ing...' >> /tmp/ddf"
        when :end
            show_num = 10
            dots = '...' if recs.size > show_num
            zones = recs[0, show_num].map(&:last).join(', ')
            dt = '%.2f' % (Time.now - @log_update_t0)
            system "echo '#{recs.size} zone(s) added in #{dt}s: #{zones}#{dots}' >> /tmp/ddf"
            Log.i "#{recs.size} zone(s) added in #{dt}s: #{zones}#{dots}"
        else
            system "echo 'Wrong param #{point} for log_update' >> /tmp/ddf"
            Log.e "Wrong param #{point} for log_update"
        end
    end

    def listen_updater_bell
        unless @conf[:http_bell_port]
            return 
        end
        require "socket"  
        dts = TCPServer.new '0.0.0.0', @conf[:http_bell_port]
        allow_ips = @conf[:http_bell_allow_ips]
        Log.i 'Starting bell listener...'
        Thread.new do
            loop do  
                Thread.start(dts.accept) do |client|
                    Log.i 'accepted'
                    numeric_address = client.peeraddr[3]
                    if !allow_ips || allow_ips.include?(numeric_address)
                        Log.i 'will update'
                        update
                    else
                        Log.w "Ignoring bell ring from #{numeric_address}."
                    end
                    Log.i 'closing connection'
                    client.close
                end
            end
        end
    end
  
end; end; end
