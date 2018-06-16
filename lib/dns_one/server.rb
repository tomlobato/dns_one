
require "dns_one/zone_search"
require "dns_one/req_log/req_log"
require "dns_one/req_log/account"
require "dns_one/req_log/db"

module DnsOne; class Server
    def initialize 
        @zone_search = ZoneSearch.instance.setup
        @req_log = nil
    end

    def start
        if RExec.current_user == 'root'
            RExec.change_user Global.conf.run_as
        end
        @req_log ||= ReqLog::ReqLog.new
        Global.logger.info "Running as #{RExec.current_user}"
    end

    def resolve transaction
        rcode = :NoError
        resp_log = []

        begin
            domain_name = transaction.question.to_s
            ip_address = transaction.options[:peer] rescue nil

            records, from_cache = @zone_search.query domain_name, transaction.resource_class, ip_address

            if records
                if records.empty?
                    transaction.fail! :NoError
                else
                    records.each do |rec|
                        resp_log << rec
                        transaction.respond! *[rec.val].flatten, {resource_class: rec.res_class, section: rec.section}
                    end
                end
            else
                rcode = :NXDomain
                transaction.fail! :NXDomain
            end
        rescue => e
            rcode = :ServFail
        end

        @req_log.on_response *[
            ip_address, 
            domain_name, 
            transaction.resource_class, 
            rcode, 
            resp_log, 
            from_cache
        ]

        raise e if e
    end

    def dns_daemon_interfaces
        if RExec.current_user == 'root'
            Global.conf.interfaces
        else
            ports = Global.conf.interfaces.map do |port|
                if port[2] <= 1024
                    Global.logger.warn "Changing listening port #{port.join ':'} to #{port[2] + 10000} for non-root process."
                    port[2] += 10000 
                end
                port
            end
            ports
        end
    end

    def run
        srv = self

        RubyDNS::run_server(dns_daemon_interfaces) do
            on(:start) do
                srv.start
            end

            match(/(.+)/) do |transaction|
                srv.resolve transaction
            end

            otherwise do |transaction|
                transaction.fail! :NXDomain
            end
        end
    end

end; end
