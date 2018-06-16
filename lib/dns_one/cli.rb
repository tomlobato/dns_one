
require "thor"
require "dns_one"
require "dns_one/setup"

class DnsOne::CLI < Thor  

    default_task :run_srv

    # RUN

    desc "run", "run server"
    option :conf
    def run_srv
        DnsOne::DnsOne.new(
            conf_file: options[:conf]
        ).start 
    end

    desc "setup", "setup dnsone"
    def setup
        DnsOne::Setup.new.setup
    end

    desc "remove", "remove dnsone"
    def remove
        DnsOne::Setup.new.remove
    end

    desc "stats", "show counters"
    def stats
        DnsOne::Stat.print
    end
end
