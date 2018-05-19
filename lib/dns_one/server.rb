
require "dns_one/zone_search"
require 'socket'
require 'json'

module DnsOne; class Server

    DEFAULT_RUN_AS = "dnsone"
    DEFAULT_LOG_RESULT_SOCKET_FILE = '/tmp/dns_one_log_result.sock'

    DNS_DAEMON_INTERFACES = [
        [:udp, "0.0.0.0", 53],
        [:tcp, "0.0.0.0", 53],
        [:udp, "::", 5300],
        [:tcp, "::", 5300]
    ]

    def initialize conf, conf_zone_search
        @conf = conf
        @zone_search = ZoneSearch.instance.setup conf_zone_search
        if conf[:log_result_socket]
            @log_result = {}
            @log_result_mutex = Mutex.new
        end
    end

    def run
        zone_search = @zone_search
        conf = @conf
        stat = nil
        if conf[:log_result_socket]
            log_result = @log_result
            log_result_mutex = @log_result_mutex
            launch_log_result_socket
            log_result_last_reset = 0
        end

        RubyDNS::run_server(listen: dns_daemon_interfaces, logger: Log.ruby_dns_logger) do
            on(:start) do
                if RExec.current_user == 'root'
                    run_as = conf[:run_as] || DEFAULT_RUN_AS
        	        stat = Stat.new user: run_as if !stat
                    RExec.change_user run_as
                else
                    stat = Stat.new if !stat
                end
                Log.i "Running as #{RExec.current_user}"
            end

            match(/(.+)/) do |t| # transaction
                rcode = :NoError
                resp_log = []

                begin
                    domain_name = t.question.to_s
                    ip_address = t.options[:peer] rescue nil

                    records, from_cache = zone_search.query domain_name, t.resource_class, ip_address

                    if records
                        if records.empty?
                            t.fail! :NoError
                        else
                            records.each do |rec|
                                resp_log << rec
                                t.respond! *[rec.val].flatten, {resource_class: rec.res_class, section: rec.section}
                            end
                        end
                    else
                        rcode = :NXDomain
                        t.fail! :NXDomain
                    end
                rescue => e
                    rcode = :ServFail
                end

                begin
                    if conf[:save_stats]
                        stat.save rcode, t.resource_class, from_cache
                    end

                    if conf[:log_result]
                        Util.log_result ip_address, domain_name, t.resource_class, rcode, resp_log, from_cache
                    end

                    if conf[:log_result_socket]
                        log_result_mutex.synchronize {
                            # Reset log_result every 5 min
                            if Time.now.to_i / 300 > log_result_last_reset / 300
                                log_result_last_reset = Time.now.to_i
                                log_result.each_key do |k|
                                    if log_result[k].is_a? Hash
                                        log_result[k].each_key do |k2|
                                            log_result[k][k2] = 0
                                        end
                                    else
                                        log_result[k] = 0
                                    end
                                end
                            end

                            log_result[:requests] ||= 0
                            log_result[:requests] += 1
                            
                            log_result[:cache] ||= 0
                            log_result[:cache] += 1 if from_cache
                            
                            rcode_uc = Util.const_underscore rcode
                            log_result[:rcode] ||= {}
                            log_result[:rcode][rcode_uc] ||= 0
                            log_result[:rcode][rcode_uc] += 1
        
                            req_resource = Util.last_mod(t.resource_class).downcase
                            log_result[:req_resource] ||= {}
                            log_result[:req_resource][req_resource] ||= 0
                            log_result[:req_resource][req_resource] += 1        
                        }
                    end
                rescue => e
                    Log.exc e
                end

                raise e if e
            end

            otherwise do |t|
                t.fail! :NXDomain
            end
        end
    end

    def dns_daemon_interfaces
        if RExec.current_user == 'root'
            DNS_DAEMON_INTERFACES
        else
            ports = DNS_DAEMON_INTERFACES.map do |port|
                if port[2] <= 1024
                    Log.w "Changing listening port #{port[2]} to #{port[2] + 10000} for non-root process."
                    port[2] += 10000 
                end
                port
            end
            ports
        end
    end

    def launch_log_result_socket
        log_result = @log_result
        log_result_mutex = @log_result_mutex
        conf = @conf

        sock = Thread.new do
            sleep 1
            begin
                Socket.unix_server_loop(conf[:log_result_socket_file] || DEFAULT_LOG_RESULT_SOCKET_FILE) do |sock, addr|
                    Thread.new do
                        loop do
                            begin
                                log_result_mutex.synchronize {
                                    sock.write "#{ log_result.to_json }\n"
                                }
                            rescue Errno::EPIPE => e
                                break
                            rescue => e
                                Log.exc e
                                break
                            end
                            Thread.pass
                            sleep 0.1
                        end
                    end
                end
            rescue => e
                Log.exc e
            end
        end
    end

end; end
