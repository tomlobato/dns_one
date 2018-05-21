module DnsOne; module ReqLog; class ReqLog

    def initialize 
        @conf = Global.conf
    end

    def on_response *args
        if @conf.log_req_db
            @db ||= Db.new
            @db.on_response *args
        end

        if @conf.log_req_file
            @file = File.new
            @file.on_response *args
        end

        if @conf.log_req_account
            @account ||= Account.new
            @account.on_response *args
        end
    end

end; end; end

