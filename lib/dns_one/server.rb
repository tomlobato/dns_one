
module DnsOne; class Server # < RExec::Daemon::Base

    DNS_DAEMON_RUN_AS = "dnsserver"
    DNS_DAEMON_INTERFACES = [
        [:udp, "0.0.0.0", 53],
        [:tcp, "0.0.0.0", 53],
        [:udp, "::", 5300],
        [:tcp, "::", 5300]
    ]

    def initialize conf, conf_zone_search
        @conf = conf
        ZoneSearch.instance.setup conf_zone_search
    end

    def run
        conf = @conf
        RubyDNS::run_server(listen: dns_daemon_interfaces, logger: Log.logger) do
            on(:start) do
                if RExec.current_user == 'root' and conf[:run_as]
                    RExec.change_user conf[:run_as]
                end
                Log.i "Running as #{RExec.current_user}"
            end

            match(/(.+)/) do |t| # transaction
                domain_name = t.question.to_s
                answer, other_records = ZoneSearch.instance.query domain_name, t.resource_class
                if answer or other_records
                    t.respond! *answer if answer
                    other_records.each do |rec|
                        t.add rec.obj, {section: rec.section}
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
