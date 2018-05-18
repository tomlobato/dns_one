# Core
require 'syslog'
require 'syslog/logger'
require 'ostruct'
require 'singleton'
require 'fileutils'

# Gems
require 'rexec'
require 'rubydns'
require 'yaml'
require 'pg'
require 'active_record'
require 'sqlite3'

# DnsOne

require "dns_one/core_ext/exception"
require "dns_one/core_ext/string"
require "dns_one/core_ext/blank"
require "dns_one/core_ext/hash"

require "dns_one/log"
require "dns_one/util"
require "dns_one/server"
require "dns_one/stat"

module DnsOne; class DnsOne

    DEFAULT_CONF_FILE = '/etc/dns_one/conf.yml'
    WORK_DIR = "/var/local/dns_one"
    CONF_DIR = "/etc/dns_one"

    def initialize conf_file: nil, work_dir: nil
        Log.setup

        conf_file ||= DEFAULT_CONF_FILE
        @conf_all = parse_conf conf_file
        @conf = @conf_all.main

        work_dir ||= WORK_DIR

        begin
            Dir.chdir work_dir
        rescue => e
            Log.w "Cannot change working dir to #{WORK_DIR}. Will continue in #{Dir.pwd}."
        end
    end

    def start
        Server.new(@conf_all.server, @conf_all.zone_search).run 
    end

    private
        
    def parse_conf conf_file
        check_conf_file conf_file

        conf = YAML.load_file conf_file
        conf = conf.symbolize_keys

        OpenStruct.new(
            main: {
                work_dir:           conf[:config][:work_dir]
            },
            server: {
                run_as:             conf[:config][:run_as],
                log_results:        (conf[:config][:log_results] == '1'),
                save_stats:           (conf[:config][:save_stats] == '1')
            },
            zone_search: {
                ignore_subdomains:  conf[:config][:ignore_subdomains],
                cache_max:          conf[:config][:cache_max],
                record_sets:        conf[:record_sets],
                backend:            conf[:backend]
            }
        )
    end

    def check_conf_file conf_file
        unless File.readable? conf_file
                Util.die "Conf file #{conf_file} not found or unreadable. Aborting." 
        end

        conf_stat = File.stat conf_file

        unless conf_stat.mode.to_s(8) =~ /0600$/
                Util.die "Conf file #{conf_file} must have mode 0600. Aborting." 
        end
    end

end; end

