
module DnsOne; class ZoneSearch
    include Singleton
    
    Name = Resolv::DNS::Name
    IN = Resolv::DNS::Resource::IN

    def setup conf
        @conf = conf
        check_record_sets
        @backend = set_backend
        @cache = Cache.new @conf.config[:cache_max]

        @ignore_subdomains_re = nil
        if ignore_subdomains = @conf.config[:ignore_subdomains]
            unless ignore_subdomains.empty?
                subdoms = ignore_subdomains.strip.split(/\s+/).map(&:downcase).join('|')
                @ignore_subdomains_re = /^(#{ subdoms })\./i
            end
        end
    end

    def query dom_name, res_class    
        dom_name = dom_name.dup

        Log.d "searching #{ dom_name }..."

        rec_set_name = find_record_set dom_name
        Log.d "record set name #{ rec_set_name ? 'found' : 'not_found' }"
        rec_set_name or return

        rec_set = @conf.record_sets[rec_set_name.to_sym]
        Log.d "record set #{ rec_set ? 'found' : 'not found' }"
        rec_set or return

        answer = nil

        unless res_class == IN::NS
            answer = rec_set[ res_class.to_s.split('::').last.to_sym ]
            answer = [answer] unless answer.is_a? Array
        end

        other_records = []

        # NS
        ns_list = rec_set[:NS].map{|ns| IN::NS.new(Name.create ns)}
        ns_section = res_class == IN::NS ? :answer : :authority
        other_records << OpenStruct.new(obj: ns_list, section: ns_section)

        [answer, other_records]
    end

    private

    def set_backend
        if file = @conf.backend[:file]
            unless File.exists? file
                Util.die "Configuration file #{file} not found."
            end
            Backend::File.new file          
        else
            Backend::DB.new @conf.backend
        end
    end

    def find_record_set dom_name
        use_cache = dom_name !~ /^NC/
        dom_name.sub! /^NC/, ''

        dom_name.downcase!

        dom_name.sub! /\.home$/i, ''
        
        if @ignore_subdomains_re
            dom_name.sub! @ignore_subdomains_re, '' 
        end

        if use_cache and rec_set = @cache.find(dom_name)
            Log.d "found in cache"
            rec_set
        else
            if rec_set = @backend.find(dom_name)
                @cache.add dom_name, rec_set if use_cache
                rec_set
            end
        end        
    end

    def check_record_sets
        unless @conf.record_sets and not @conf.record_sets.empty?
            Util.die "Record sets cannot be empty. Check file."
        end

        @conf.record_sets.each_pair do |rec_set_name, records|
            unless records[:NS] and records[:NS].length >= 1
                Util.die "Record set #{rec_set_name} is invalid. It must have at least 1 NS record."
            end
            unless records[:SOA] and records[:SOA].length == 7
                Util.die "Record set #{rec_set_name} is invalid. It must have a valid SOA record."
            end
        end
    end

end; end


