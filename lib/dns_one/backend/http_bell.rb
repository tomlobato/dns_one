
# HTTPBell
# At initialization:
# 1) Fetches all domains from @conf[:http_bell_url] and keeps in memory
# 2) Open TCP port @conf[:http_bell_port] and fetches new domains incrementally upon connect(2)

module DnsOne; module Backend; class HTTPBell < Base

    LOG_DOM_NUM = 10

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
                    Global.logger.warn "invalid line '#{r}'"
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
            Global.logger.info "update`ing..."
        when :end
            dt = '%.2f' % (Time.now - @log_update_t0)
            dots = '...' if recs.size > LOG_DOM_NUM
            zones = recs[0, LOG_DOM_NUM].map(&:last).join(', ')
            Global.logger.info "#{recs.size} zone(s) added in #{dt}s: #{zones}#{dots}"
        else
            Global.logger.error e.desc "Wrong param #{point} for log_update"
        end
    rescue => e
        Global.logger.error e.desc
    end

    def listen_updater_bell
        unless @conf[:http_bell_port]
            return 
        end
        require "socket"  
        dts = TCPServer.new '0.0.0.0', @conf[:http_bell_port]
        allow_ips = @conf[:http_bell_allow_ips]
        Global.logger.info 'Starting bell listener...'
        Thread.new do
            loop do  
                Thread.start(dts.accept) do |client|
                    Global.logger.info 'accepted'
                    numeric_address = client.peeraddr[3]
                    if !allow_ips || allow_ips.include?(numeric_address)
                        Global.logger.info 'will update'
                        update
                    else
                        Global.logger.warn "Ignoring bell ring from #{numeric_address}."
                    end
                    Global.logger.info 'closing connection'
                    client.close
                end
            end
        end
    end
  
end; end; end
