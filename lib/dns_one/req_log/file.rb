module DnsOne; module ReqLog; class File
    if  self.set_logger
        path = @conf.req_log_file.is_a?(String) ? @conf.req_log_file : STDOUT

        l = Logger.new @conf.ruby_dns_logger, 10, (10 * 2**20)
        l.level = Logger::WARN

        Global.ruby_dns_logger = l
    end

    def self.log_result ip_address, domain_name, res_class, rcode, resp_log, from_cache
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

        Global.logger.info "result: #{ fields.join ' ' }"
    end
end
   
