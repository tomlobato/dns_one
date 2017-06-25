# Core
require 'syslog'
require 'syslog/logger'

# Gems
require 'rubydns'
require 'active_record'
require 'yaml'
require 'rexec'

# DnsOne

require "dns_one/core_extensions"
require "dns_one/log"
require "dns_one/util"

require "dns_one/server"
require "dns_one/setup"
require "dns_one/cache"
require "dns_one/zone_search"

require 'dns_one/backend/file'
require 'dns_one/backend/db'

module DnsOne; class DnsOne

	DEFAULT_LOG_FILE = "/var/log/dns_server.log"
	DEFAULT_CONF_FILE = '/etc/dns_one/conf.yml'
	WORK_DIR = "/var/local/dnsserver"

	CONF_DIR = "/etc/dns_one"
	SYSLOG_NAME = 'dns_one'

	def initialize conf_file: nil, log_file: nil
		log_file  ||= DEFAULT_LOG_FILE
		conf_file ||= DEFAULT_CONF_FILE

		Log.setup log_file, SYSLOG_NAME
		@conf = parse_conf conf_file

		# check_root
		begin
			Dir.chdir (@conf.config[:work_dir] || WORK_DIR)
		rescue => e
			Log.w "Cannot change working dir to #{WORK_DIR}. Will continue in #{Dir.pwd}."
		end
	end

	def start
		Server.new(@conf).run 
	end

	private

	def parse_conf conf_file
		check_conf_file conf_file

		conf = YAML.load_file conf_file
		conf.deep_symbolize_keys!

		conf[:config] ||= {}

		OpenStruct.new conf
	end

	def check_conf_file conf_file
		unless File.readable? conf_file
				Util.die "Conf file #{conf_file} not found or unreadable. Aborting." 
		end

		conf_stat = File.stat conf_file

		unless conf_stat.mode.to_s(8) =~ /0600$/
				# Util.die "Conf file #{conf_file} must have mode 0600. Aborting." 
		end

		unless match_root conf_stat
				# Util.die "Conf file #{conf_file} must have uid/gid set to root. Aborting." 
		end
	end

end; end

