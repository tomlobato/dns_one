module DnsOne; class Util
    
  DOM_REGEX = /^[a-z0-9]+([\-\.][a-z0-9]+)*\.[a-z]{2,32}$/i

  class << self
    def die msg
      Log.f msg
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

    def log_result ip_address, domain_name, res_class, rcode, resp_log, from_cache
      fields = []

      fields << domain_name
      fields << Util.last_mod(res_class)
      fields << rcode
      fields << resp_log.map{ |rec|
          Util.last_mod(rec.res_class) + 
          ':' +
          [rec.val].flatten.join(',')
      }.join(';')
      fields << ip_address
      fields << (from_cache ? '1' : '0')

      fields.map!{|v| v.blank? ? '-' : v}

      Log.i "result: #{ fields.join ' ' }"
    end
  end 

end; end
