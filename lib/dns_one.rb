# Core
require 'syslog'
require 'syslog/logger'

# Gems
require 'rubydns'
require 'active_record'
require 'yaml'
require 'rexec'

# DnsOne

require "dns_one/core_ext/exception"
require "dns_one/core_ext/string"
require "dns_one/core_ext/blank"

require "dns_one/log"
require "dns_one/util"

require "dns_one/server"
require "dns_one/setup"
require "dns_one/cache"
require "dns_one/zone_search"

require 'dns_one/backend/file'
require 'dns_one/backend/db'

module DnsOne; class DnsOne

	DEFAULT_LOG_FILE = "/var/log/dns_one.log"
	DEFAULT_CONF_FILE = '/etc/dns_one/conf.yml'
	WORK_DIR = "/var/local/dns_one"

	CONF_DIR = "/etc/dns_one"
	SYSLOG_NAME = 'dns_one'

	def initialize conf_file: nil, log_file: nil, work_dir: nil
		cmd_log_file = log_file
		log_file ||= DEFAULT_LOG_FILE
		Log.setup log_file, SYSLOG_NAME

		conf_file ||= DEFAULT_CONF_FILE
		@conf_all = parse_conf conf_file
		@conf = @conf_all.main

		work_dir ||= WORK_DIR

		# Redefine log file if set in conf file
		unless cmd_log_file
			if f = @conf[:log_file].presence 
				unless Log.change_log_file f
					Log.w "Unable to change logfile to #{f}. Will continue with #{Log.log_file_desc}."
				end
			end
		end

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
		conf.deep_symbolize_keys!

		OpenStruct.new(
			main: {
				work_dir: conf[:work_dir],
				log_file: conf[:log_file]
			},
			server: {
				run_as: conf[:run_as]
			},
			zone_search: {
				ignore_subdomains: conf[:ignore_subdomains],
				cache_max: conf[:cache_max],
				record_sets: conf[:record_sets],
				backend: conf[:backend]
			}
		)
	end

	def check_conf_file conf_file
		unless File.readable? conf_file
				Util.die "Conf file #{conf_file} not found or unreadable. Aborting." 
		end

		conf_stat = File.stat conf_file

		unless conf_stat.mode.to_s(8) =~ /0600$/
				# Util.die "Conf file #{conf_file} must have mode 0600. Aborting." 
		end

		unless Util.match_root conf_stat
				# Util.die "Conf file #{conf_file} must have uid/gid set to root. Aborting." 
		end
	end

end; end

