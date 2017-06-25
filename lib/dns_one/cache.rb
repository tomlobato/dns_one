
module DnsOne; class Cache
    DEFAULT_MAX_SIZE = 10000

    def initialize max_size = nil
        @max_size = max_size || DEFAULT_MAX_SIZE
        @cache = {}
    end

    def add k, v
        @cache[k] = v
        if @cache.length > @max_size
            @cache.delete @cache.keys.first 
        end
        v
    end

    def find k
        @cache[k]
    end
    
end; end
