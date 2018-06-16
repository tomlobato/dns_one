module DnsOne; class Util
    
  DOM_REGEX = /^[a-z0-9]+([\-\.][a-z0-9]+)*\.[a-z]{2,32}$/i

  class << self
    def die msg
      Global.logger.fatal msg
      exit 1
    end

    def run cmd
        puts "Running #{cmd}..."
        system cmd
    end

    def has_systemd?
        File.exist?(`which systemctl`.strip) && 
        File.writable?('/lib/systemd/system')
    end

    def ensure_sytemd
        unless has_systemd?
            STDERR.puts "Systemd not available. Aborting." 
            exit 1
        end
    end

    def match_root stat
        stat.uid == 0 && stat.gid == 0
    end

    def last_mod constant
      constant.to_s.split('::').last
    end

    def const_underscore name
        name = name.to_s.dup
        name.gsub!('::', '/')
        name.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
        name.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        name.tr!("-", "_")
        name.downcase!
        name
    end

    def hash_to_ostruct_deep hash
        os = OpenStruct.new
        hash.each_pair{ |k, v| 
            if v.is_a? Hash
                os[k] = hash_to_ostruct_deep v
            else
                os[k] = v
            end
        }
        os
    end

    def init_logger logdev, level = Logger::WARN, shift_age = 10, shift_size = 2**20
        if logdev.is_a? String
            begin
                if File.exists? logdev
                    File.writable? logdev
                else
                    FileUtils.mkdir_p File.dirname(logdev)
                end
            rescue => e
                $stderr.puts "#{e.desc}\nCannot open log file #{logdev}. Will use STDOUT."
                logdev = $stdout
            end
        end
        l = Logger.new logdev, shift_age, shift_size
        l.level = level
        l
    end

  end 

end; end
