module Backend; class DB
    def initialize conf
        @query = conf.delete :query
        @db_conf = conf
        setup_db
    end

    def find dom_name
        sql = build_query dom_name
        # http://jakeyesbeck.com/2016/02/14/ruby-threads-and-active-record-connections/
        res = nil
        begin
            ActiveRecord::Base.connection_pool.with_connection do
                res = ActiveRecord::Base.connection.execute sql
            end
        rescue => e
            Log.exc e
        end
        first_record = res&.first
        record_values = first_record&.values
        record_values&.first
    end

    private

    def build_query dom_name
        @query.sub '$domain', dom_name
    end

    def setup_db
        ActiveRecord::Base.logger = Log.logger
        ActiveRecord::Base.establish_connection @db_conf
    end
  
end; end
