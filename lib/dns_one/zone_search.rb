
require "dns_one/cache"
require 'dns_one/backend/base'
require 'dns_one/backend/http_bell'
require 'dns_one/backend/file'
require 'dns_one/backend/db'

module DnsOne; class ZoneSearch
    include Singleton
    
    Name = Resolv::DNS::Name
    IN = Resolv::DNS::Resource::IN

    def setup
        @conf = Global.conf
        check_record_sets
        @backend = set_backend
        @cache = Cache.new Global.conf.cache_max
        @ignore_subdomains_re = build_ignore_subdomains_re

        if @backend.preload_dummy?
            query 'dummy.com.br', Resolv::DNS::Resource::IN, '1.2.3.4'
        end

        self
    end

    def query dom_name, res_class, ip_address
        return unless dom_name =~ Util::DOM_REGEX

        dom_name = dom_name.dup
        res_class_short = Util.last_mod res_class # :A, :NS, found in conf.yml:record_sets items
        Global.logger.debug "request #{ dom_name }/#{res_class_short} from #{ip_address}..."

        records = []

        rec_set_name, from_cache = find_record_set dom_name
        Global.logger.debug "domain #{ rec_set_name ? "found, rec_set_name = '#{rec_set_name}'" : 'not found' }"
        return unless rec_set_name

        # use first record set if rec_set_name == ''
        rec_set_name = @conf.record_sets.to_h.keys.first if rec_set_name == ''
 
        rec_set = @conf.record_sets[rec_set_name]
        Global.logger.debug "record set #{ rec_set ? 'found' : 'not found' }"
        return records unless rec_set

        # TODO: move parsing logic to own class

        recs = rec_set[res_class_short.to_sym]
        Global.logger.debug "record(s) #{ recs ? 'found' : 'not found' }"

        # Loop over 1 or more
        recs = [recs]
        recs.flatten! unless res_class == IN::SOA

        recs.compact.each do |val_raw|
            val = if res_class == IN::NS
                Name.create val_raw
            elsif res_class == IN::SOA
                [0, 1].each{|i| val_raw[i] = Name.create val_raw[i] }
                val_raw
            else
                val_raw
            end
            records << OpenStruct.new(val: val, res_class: res_class, section: 'answer')
        end

        [records, from_cache]
    end

    private

    def build_ignore_subdomains_re
        if i = @conf.ignore_subdomains.presence
            s = i.strip.split(/\s+/).map(&:downcase).join '|'
            /^(#{ s })\./i
        end
    end

    def set_backend
        if file = @conf.backend.file
            unless ::File.exists? file
                Util.die "Domain list file #{file} not found (pwd = #{Dir.pwd})."
            end
            Backend::File.new file
        elsif @conf.backend.http_bell_url
            unless @conf.backend.http_bell_record_set
                Util.die "backend.http_bell_record_set not set."
            end
            Backend::HTTPBell.new @conf.backend
        else
            Backend::DB.new @conf.backend
        end
    end

    def find_record_set dom_name
        dom_name, use_cache = check_debug_tags dom_name
        dom_name = normalize_domain dom_name
        
        enabled_cache = use_cache && @backend.allow_cache

        if enabled_cache and rec_set = @cache.find(dom_name)
            Global.logger.debug "found in cache (#{@cache.stat})"
            [rec_set, true]
        else
            if rec_set = @backend.find(dom_name)
                @cache.add dom_name, rec_set if enabled_cache
                [rec_set, false]
            end
        end        
    end

    def normalize_domain dom_name
        dom_name = dom_name.dup

        dom_name.sub! @ignore_subdomains_re, '' if @ignore_subdomains_re
        dom_name.downcase!
        dom_name.sub! /\.home$/i, ''

        dom_name
    end

    def check_debug_tags dom_name
        use_cache = true
        if dom_name.sub!(/^NC/, '')
            use_cache = false 
        end
        [dom_name, use_cache]
    end

    def check_record_sets
        if @conf.record_sets.blank?
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


