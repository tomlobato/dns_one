module DnsOne; class Setup
    # Currently tested version 
    # TODO: flexibilize version and make checks/prompts/warnings during install
    REQUIRED_RUBY_VERSION = '2.3.3' 

    SYSTEMD_SERVICES_DIR = "/lib/systemd/system/"
    SERVICE_NAME = 'dns_one'
    SYSTEMD_SERVICE_FILE = "#{SYSTEMD_SERVICES_DIR}/#{SERVICE_NAME}.service"


    def initialize
        @thisdir = File.join File.dirname(__FILE__)
    end

    def install
        check_root
        #check_ruby_version
        unless Util.has_systemd?
            STDERR.puts "DnsOne requires systemd. Aborting install."
            exit 1
        end
        add_user
        mkdirs
        #set_ruby_version
        copy_sample_conf
        install_systemd_service
        setup_finished_msg
    end

    def uninstall
        # File.delete DnsOne::DEFAULT_CONF_FILE # TODO: prompt user
        if File.exist?(SYSTEMD_SERVICE_FILE)
            Util.run "systemctl stop #{SERVICE_NAME}" 
            Util.run "systemctl disable #{SERVICE_NAME}" 
            File.delete SYSTEMD_SERVICE_FILE
        end
        FileUtils.rm_rf DnsOne::WORK_DIR
        # TODO: prompt if should remove user
        puts "Uninstall complete."
    end

    private

    def check_ruby_version
        if RUBY_VERSION != REQUIRED_RUBY_VERSION
            STDERR.puts "Currently dns_one supports #{REQUIRED_RUBY_VERSION} only. Aborting install."
            exit 1
        end
    end

    def add_user
        if `cat /etc/passwd|grep ^#{Server::DEFAULT_RUN_AS}:`.strip.present?
            STDOUT.puts "User #{Server::DEFAULT_RUN_AS} exists, skipping creation."            
        else
            # TODO: prompt user
            system "adduser --system --no-create-home #{Server::DEFAULT_RUN_AS}"
        end
    end

    def set_ruby_version
        File.write "#{DnsOne::WORK_DIR}/.ruby-version", REQUIRED_RUBY_VERSION
    end

    def mkdirs
        FileUtils.mkdir_p DnsOne::CONF_DIR

        FileUtils.mkdir_p DnsOne::WORK_DIR
        File.chmod 0755, DnsOne::WORK_DIR
        File.chown `id -u #{Server::DEFAULT_RUN_AS}`.to_i, nil, DnsOne::WORK_DIR
    end

    def setup_finished_msg
        puts "Installed.\n"
        puts "Now:"
        puts "1) Edit #{DnsOne::DEFAULT_CONF_FILE}. You can run 'ruby -Ilib/ exe/dns_one --conf util/dev_conf.yml --log=/dev/stdout' to test and adjust your configuration."
        puts "2) After configure run 'dns_one start'."
        puts "See startup logs with 'tail -f /var/log/syslog'"
        puts "See run logs with 'tail -f /var/log/dns_one.log' (or /var/log/dns_one_rubydns.log)"
    end

    def is_setup?
        File.exist?(DnsOne::DEFAULT_CONF_FILE) &&
        File.exist?(SYSTEMD_SERVICE_FILE)
    end

    def check_root
        unless Process.uid == 0
            STDERR.puts "Install requires root privileges. Run with sudo or login as root. Aborting."
            exit 1
        end
    end

    def install_systemd_service
        copy "#{@thisdir}/../../util/dns_one.service", 
             SYSTEMD_SERVICE_FILE

        Util.run "systemctl enable #{SERVICE_NAME}"
    end

    def copy_sample_conf
        if File.exist? DnsOne::DEFAULT_CONF_FILE
            STDOUT.puts "File #{DnsOne::DEFAULT_CONF_FILE} exists, skipping creation."
        else
            copy "#{@thisdir}/../../util/sample_conf.yml", 
                 DnsOne::DEFAULT_CONF_FILE
        end
    end

    def copy from, to, mod = 0600
        puts "Copying #{from} to #{to}..."
        FileUtils.cp from, to
        FileUtils.chmod mod, to
    end

end; end
