
require "thor"
require 'sqlite3'
require "dns_one"
require "dns_one/setup"

class DnsOne::CLI < Thor  

    default_task :run_srv

    # RUN

    desc "run", "run server"
    option :conf
    option :work_dir
    def run_srv
        DnsOne::DnsOne.new(
            conf_file: options[:conf], 
            work_dir: options[:work_dir]
        ).start 
    end

    # INSTALL

    desc "install", "install dns_one"
    def install
        DnsOne::Setup.new.install
    end

    desc "uninstall", "uninstall dns_one"
    def uninstall
        DnsOne::Setup.new.uninstall
    end

    # MANAGE

    desc "start", "start dns_one"
    def start
        DnsOne::Util.ensure_sytemd
        DnsOne::Util.run "systemctl start #{DnsOne::Setup::SERVICE_NAME}"
    end

    desc "stop", "stop dns_one"
    def stop
        DnsOne::Util.ensure_sytemd
        DnsOne::Util.run "systemctl stop #{DnsOne::Setup::SERVICE_NAME}"
    end

    desc "status", "check dns_one status"
    def status
        DnsOne::Util.ensure_sytemd
        DnsOne::Util.run "systemctl status #{DnsOne::Setup::SERVICE_NAME}"
    end

    # STATS

    desc "stats", "show counters"
    def stats
        DnsOne::Stat.print
    end
end
