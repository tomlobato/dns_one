
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
        last_id = @last_id || 0

        url = @conf[:http_bell_url].sub '$id', last_id.to_s

        recs = `curl #{url}`
            .split("\n")
            .map{ |r| 
                r.strip.split /\s+/
            }

        recs.each do |rec|
            id, domain = rec
            id = id.to_i
            @domains[domain] = @conf[:http_bell_record_set]
            if !@last_id || @last_id < id
                @last_id = id
            end
        end

        Log.d "#{recs.size} new domains added."
    end

    def listen_updater_bell
        unless @conf[:http_bell_bell_port]
            return 
        end
        require "socket"  
        dts = TCPServer.new '0.0.0.0', @conf[:http_bell_bell_port]
        Thread.new do
            loop do  
                Thread.start(dts.accept) do |s|
                    s.close
                    Log.i "update`ing..."
                    update
                end  
            end  
        end
    end
  
end; end; end
