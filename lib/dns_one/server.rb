
module DnsOne; class Server # < RExec::Daemon::Base

    DEFAULT_RUN_AS = "dnsone"

    DNS_DAEMON_INTERFACES = [
        [:udp, "0.0.0.0", 53],
        [:tcp, "0.0.0.0", 53],
        [:udp, "::", 5300],
        [:tcp, "::", 5300]
    ]

    def initialize conf, conf_zone_search
        @conf = conf
        @zone_search = ZoneSearch.instance.setup conf_zone_search
    end

    def run
        zone_search = @zone_search
        conf = @conf

        RubyDNS::run_server(listen: dns_daemon_interfaces, logger: Log.logger) do
            on(:start) do
                if RExec.current_user == 'root'
                    run_as = conf[:run_as] || DEFAULT_RUN_AS
                    RExec.change_user run_as
                end
                Log.i "Running as #{RExec.current_user}"
            end

            match(/(.+)/) do |t| # transaction
                domain_name = t.question.to_s
                ip_address = t.options[:peer] rescue nil

                records = zone_search.query domain_name, t.resource_class, ip_address

                if records
                    if records.empty?
                        t.fail! :NoError
                    else
                        records.each do |rec|
                            t.respond! *[rec.val].flatten, {resource_class: rec.res_class, section: rec.section}
                        end
                    end
                else
                    t.fail! :NXDomain
                end
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

end; end
