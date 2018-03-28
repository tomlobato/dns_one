module DnsOne; module Backend; class Base
    def allow_cache
        true
    end

    def preload_dummy?
        false
    end
end; end; end
