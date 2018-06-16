# Core
require 'ostruct'
require 'singleton'
require 'fileutils'
require 'socket'
require 'json'

# Gems
require 'rexec'
require 'rubydns'
require 'yaml'

# DnsOne

require "dns_one/core_ext/exception"
require "dns_one/core_ext/string"
require "dns_one/core_ext/blank"
require "dns_one/core_ext/hash"

require "dns_one/global"
require "dns_one/util"
require "dns_one/server"

module DnsOne; class DnsOne

    DEFAULTS = {
        conf_file:          "/etc/dnsone.yml",
        work_dir:           "/var/local/dnsone",
        log_file:           "/var/log/dnsone/dnsone.log",
        rubydns_log_file:   "/var/log/dnsone/dnsone_rubydns.log",
        run_as:             "dnsone",
        interfaces:         [ [:udp, "0.0.0.0", 53],
                              [:tcp, "0.0.0.0", 53],
                              [:udp, "::", 5300],
                              [:tcp, "::", 5300] 
                            ],
        log_req_socket_file: '/tmp/dnsone_log_result.sock'
    }

    def initialize conf_file: nil
        @conf = Global.conf = load_conf(conf_file || DEFAULTS[:conf_file])
    end
    
    def start
        init_loggers
        chdir
        Server.new.run 
    end

    private

    def load_conf conf_file
        conf = DEFAULTS.clone
        if File.exists? conf_file
            conf.merge! YAML.load_file(conf_file).symbolize_keys
        end
        Util.hash_to_ostruct_deep conf

    rescue => e
        $stderr.puts e.desc
        $stderr.puts "Error opening conf file #{conf_file}. Aborting."
        exit 1
    end

    def init_loggers
        Global.logger           = Util.init_logger @conf.log_file       , Logger::INFO
        Global.ruby_dns_logger  = Util.init_logger @conf.ruby_dns_logger, Logger::WARN
    end

    def chdir
        d = @conf.work_dir
        FileUtils.mkdir_p d
        Dir.chdir d

    rescue => e
        Global.logger.error e.desc
        Global.logger.error "Cannot chdir to #{@conf.work_dir}. Will continue in #{Dir.pwd}"
    end

end; end
