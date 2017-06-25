module DnsOne; class Util; class << self

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

end; end; end
