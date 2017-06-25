require "dns_one"
require "dns_one/setup"
require "thor"

class DnsOne::CLI < Thor    

    desc "run", "run server"
    option :conf
    option :log
    def run_srv
        DnsOne::DnsOne.new(conf_file: options[:conf], log_file: options[:log]).start 
    end

    desc "setup", "setup dns_one"
    def setup
        DnsOne::Setup.setup
    end

    desc "install", "install dns_one"
    def install
        DnsOne::Setup.install
    end

    desc "uninstall", "uninstall dns_one"
    def uninstall
        DnsOne::Setup.uninstall
    end

    desc "start", "start dns_one"
    def start
        run_cmd "systemctl start #{DnsOne::Setup::SERVICE_NAME}"
    end

    desc "stop", "stop dns_one"
    def stop
        run_cmd "systemctl stop #{DnsOne::Setup::SERVICE_NAME}"
    end

    desc "status", "check dns_one status"
    def status
        run_cmd "systemctl status #{DnsOne::Setup::SERVICE_NAME}"
    end

    private

    def run_cmd cmd
        puts "Running #{cmd}..."
        system cmd
    end

    default_task :run_srv
end
