module DnsOne; module Backend; class DB < Base

    def initialize conf
        @query = conf.delete :query
        @conf = conf
        setup_db
    end

    def find dom_name
        query build_query(dom_name)
    end

    # Find a dummy zone to make AR/pg load all dependencies
    def preload_dummy?
        true
    end

    private

    def query sql, tries = 1
        return if tries > 3

        # http://jakeyesbeck.com/2016/02/14/ruby-threads-and-active-record-connections/
        res = ActiveRecord::Base.connection_pool.with_connection do
            ActiveRecord::Base.connection.execute sql
        end

        first_record = res&.first
        record_values = first_record&.values
        record_values&.first

    rescue ActiveRecord::StatementInvalid => e
        Global.logger.error "SQL query error. Trying to reconnect #{tries}. Details:\n#{e.desc}"
        # http://geoff.evason.name/2015/01/18/postgres-ssl-connection-has-been-closed-unexpectedly
        ActiveRecord::Base.connection.reconnect! 
        find sql, (tries+1)
    rescue => e
        Global.logger.error "SQL query error. Details:\n#{e.desc}"
    end

    def build_query dom_name
        @query.sub "'$domain'", 
                    ActiveRecord::Base.connection.quote(dom_name)
    end

    def setup_db
        require_deps
        ActiveRecord::Base.logger = Global.logger
        ActiveRecord::Base.establish_connection @conf
    end

    def require_deps
        gem_name = { 
            'postgresql' => 'pg',
            'mysql'      => 'mysql',
            'mysql2'     => 'mysql2'
        }[ @conf[:adapter] ]
          
        unless gem_name
            Util.die "Database adapter '#{@conf[:adapter]}' not supported. Aborting."
        end

        ['active_record', gem_name].each do |req_name|
            begin
                require req_name
            rescue StandardError, LoadError => e
                Util.die "Error on 'require #{req_name}', install with 'gem install #{req_name}'.\nError Details: #{e.desc}"
            end
        end
    end
  
end; end; end
