require "thor"

require "dns_one"
require "dns_one/setup"

class DnsOne::CLI < Thor  

    # RUN

    desc "run", "run server"
    option :conf
    option :log
    option :work_dir
    def run_srv
        DnsOne::DnsOne.new(conf_file: options[:conf], log_file: options[:log], work_dir: options[:work_dir]).start 
    end
    default_task :run_srv

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
end
