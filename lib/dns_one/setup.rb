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
        unless Util.has_systemd?
            STDERR.puts "DnsOne requires systemd. Aborting install."
            exit 1
        end
        mkdirs
        set_ruby_version
        copy_sample_conf
        add_user
        install_systemd_service
        setup_finished_msg
    end

    def uninstall
        stop
        # File.delete DnsOne::DEFAULT_CONF_FILE
        if File.exist?(SYSTEMD_SERVICE_FILE)
            Util.run "systemctl disable #{SERVICE_NAME}" 
            File.delete SYSTEMD_SERVICE_FILE
        end
        FileUtils.rm_rf DnsOne::WORK_DIR
        puts "Uninstall complete."
    end

    private

    def add_user
        # TODO: prompt user
        system "adduser --system --no-create-home #{DnsOne::Server::DEFAULT_RUN_AS}"
    end

    def set_ruby_version
        File.write "#{WORK_DIR}/.ruby-version", REQUIRED_RUBY_VERSION
    end

    def mkdirs
        FileUtils.mkdir_p DnsOne::CONF_DIR
        FileUtils.mkdir_p DnsOne::WORK_DIR
    end

    def setup_finished_msg
        puts "Installed.\n"
        puts "Now:"
        puts "1) Edit #{DnsOne::DEFAULT_CONF_FILE}. You can run 'ruby -Ilib/ exe/dns_one --conf util/dev_conf.yml' to test and adjust your configuration."
        puts "2) After configure run 'dns_one start'."
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
        copy "#{@thisdir}/../../util/sample_conf.yml", 
             DnsOne::DEFAULT_CONF_FILE
    end

    def copy from, to, mod = 0600
        puts "Copying #{from} to #{to}..."
        FileUtils.cp from, to
        FileUtils.chmod mod, to
    end

end; end
