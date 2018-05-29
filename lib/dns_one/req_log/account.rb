module DnsOne; module ReqLog; class Account

    def initialize
        @conf = Global.conf       

        @stat = {}
        @stat_mutex = Mutex.new
        
        @last_stat = nil
        @last_stat_mutex = Mutex.new

        Thread.new { open_socket }
        Thread.new { reap }
    end

    def on_response ip_address, domain_name, res_class, rcode, resp_log, from_cache
        @stat_mutex.synchronize {
            @stat[:requests] ||= 0
            @stat[:requests] += 1
            
            @stat[:cache] ||= 0
            @stat[:cache] += 1 if from_cache
            
            rcode_uc = Util.const_underscore rcode
            @stat[:rcode] ||= {}
            @stat[:rcode][rcode_uc] ||= 0
            @stat[:rcode][rcode_uc] += 1

            req_resource = Util.last_mod(res_class).downcase
            @stat[:req_resource] ||= {}
            @stat[:req_resource][req_resource] ||= 0
            @stat[:req_resource][req_resource] += 1        
        }
    rescue => e
        Global.logger.error e.desc
    end

    def update_last_stat stat
        if !@allow_update_last_stat
            @allow_update_last_stat = true
            return
        end
        @last_stat_mutex.synchronize {
            @last_stat = stat
        }
    end

    def reap
        loop do
            sleep (300 - Time.now.to_f % 300)
            stat = nil
            @stat_mutex.synchronize { 
                stat = @stat.deep_dup 
                reset @stat
            }
            update_last_stat stat
        rescue => e
            Global.logger.error e.desc
            sleep 10
        end
    end

    def write_socket sock
        last_stat = @last_stat_mutex.synchronize{ @last_stat.deep_dup }
        sock.puts last_stat.to_json
    rescue => e
        Global.logger.error e.desc
    end

    def open_socket
        sleep 1 # wait for UID change before create the socket file
        Socket.unix_server_loop(Global.conf.log_req_socket_file) do |sock, addr|
            Thread.new do
                write_socket sock
            end
        end
    rescue => e
        Global.logger.error e.desc
    end

    def reset hash
        hash.each_key do |k|
            if hash[k].is_a? Hash
                reset hash[k]
            else
                hash[k] = 0
            end
        end
    end

end; end; end

