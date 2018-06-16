module DnsOne; class Setup
    SYSTEMD_SERVICES_DIR = "/lib/systemd/system/"
    SERVICE_NAME = 'dnsone'
    SYSTEMD_SERVICE_FILE = "#{SYSTEMD_SERVICES_DIR}/#{SERVICE_NAME}.service"

    attr_accessor :conf

    def initialize
        @thisdir = File.join File.dirname(__FILE__)
        DnsOne.new # just to load the configuration 
                   # TODO: move conf to own class
        @conf = Global.conf
    end

    def setup
        check_reqs
        add_user
        mkdirs
        copy_sample_conf
        install_systemd_service
        setup_finished_msg
    end

    def remove
        unless is_setup?
            die "Nothing to remove. Exiting."
        end

        # SYSTEMD_SERVICE_FILE
        if Util.has_systemd? and File.exist? SYSTEMD_SERVICE_FILE 
            Util.run "systemctl stop #{SERVICE_NAME}" 
            Util.run "systemctl disable #{SERVICE_NAME}" 
            File.delete SYSTEMD_SERVICE_FILE
        end
        
        # conf_file
        if File.exists? conf.conf_file
            if confirm? "Delete #{conf.conf_file}?"
                FileUtils.rm conf.conf_file
            end
        end
        
        # work_dir
        if conf.work_dir == '/var/local/dnsone' # Only deletes if path matches the hardcoded one
            if Dir.exists? conf.work_dir
                if confirm? "Delete #{conf.work_dir}?"
                    FileUtils.rm_rf conf.work_dir
                end
            end
        end

        puts "Removed."
    end

    private

    def check_reqs
        unless Process.uid == 0
            die  "Install requires root privileges. Run with sudo or login as root. Aborting."
        end
        unless Util.has_systemd?
            warn "DnsOne will install without systemd."
        end
    end

    def add_user
        if `cat /etc/passwd|grep ^#{conf.run_as}:`.strip.present?
            warn "User #{conf.run_as} exists, skipping creation."
            return
        end
        system "adduser --system --no-create-home '#{conf.run_as}'"
    end

    def mkdirs
        if Dir.exists? conf.work_dir
            warn "Work dir #{conf.work_dir} exists, skipping creation."
            return
        end
        FileUtils.mkdir_p conf.work_dir
        File.chmod 0755, conf.work_dir
        File.chown `id -u #{conf.run_as}`.to_i, nil, conf.work_dir
    end

    def setup_finished_msg
        print <<~HEREDOC

            Installed successfully

            Now:
            1) Edit #{conf.conf_file}
            2) After configuration run 'dnsone' (or 'systemctl start dnsone' if systemd is available)

            Logs are sent to /var/log/dnsone.log 
                             /var/log/dnsone_rubydns.log

        HEREDOC
    end

    def is_setup?
        File.exist? conf.conf_file
    end

    def install_systemd_service
        copy "#{@thisdir}/../../util/dnsone.service", 
             SYSTEMD_SERVICE_FILE

        Util.run "systemctl enable #{SERVICE_NAME}"
    end

    def copy_sample_conf
        if File.exist? conf.conf_file
            unless confirm? "File #{conf.conf_file} exists. Override it?"
                return
            end
        end
        copy "#{@thisdir}/../../util/sample_conf.yml", 
             conf.conf_file
    end

    def copy from, to, mod = 0600
        puts "Copying #{from} to #{to}..."
        FileUtils.cp from, to
        FileUtils.chmod mod, to
    
    rescue => e
        warn "Error when copying #{from} to #{to}: #{e.message}"
        unless confirm? "Ignore error?"
            die "exiting"
        end
    end

    def die msg
        STDERR.puts msg
        exit 1
    end

    def warn msg
        STDERR.puts msg
    end

    def confirm? msg
        typed = nil
        loop do
            print "#{msg} (y/n): "
            typed = STDIN.gets.chomp
            break if %w(y n).include? typed
        end
        typed == 'y'
    end

end; end
