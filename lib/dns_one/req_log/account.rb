module DnsOne; module Backend; class Account

    def initialize
        @conf = Global.conf       
        @stat = {}
        @last_stat = nil
        @mutex = Mutex.new
        open_socket
        reap
    end

    def on_response ip_address, domain_name, res_class, rcode, resp_log, from_cache
        @mutex.synchronize {
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
    end

    def reap
        Thread.new do
            loop do
                sleep (300 - Time.now.to_f % 300)
                @mutex.synchronize {
                    @last_stat = @stat.deep_dup
                    reset @stat
                }
            end
        end
    end

    def open_socket
        conf = @conf
        mutex = @mutex
        stat = @stat
        sock = Thread.new do
            sleep 1
            begin
                Socket.unix_server_loop(Global.conf.log_req_socket_file) do |sock, addr|
                    Thread.new do
                        loop do
                            begin
                                mutex.synchronize {
                                    sock.write "#{ last_stat.to_json }\n"
                                }
                            rescue Errno::EPIPE => e
                                break
                            rescue => e
                                Global.logger.error e.desc
                                break
                            end
                            Thread.pass
                            sleep 0.1
                        end
                    end
                end
            rescue => e
                Global.logger.error e.desc
            end
        end
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

end
